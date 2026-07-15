# Labels a channel's legend would show, mirroring the labeling logic in the
# builder loop below without actually drawing anything.
function _channel_legend_labels(y, lbl)
    isnothing(lbl) && return String[]
    out = []
    for (j, yy) in pairs(y)
        if yy isa AbstractVector
            l = (lbl isa AbstractVector && j <= length(lbl)) ? string(lbl[j]) : ""
            l != "" && push!(out, l)
        else
            l = lbl isa AbstractVector ? "" : string(lbl)
            l != "" && push!(out, l)
            break
        end
    end
    return out
end

# Actual pixel height a channel's row needs to fit its axislegend without
# overlapping the title band above or the x-axis ticks/label below, measured
# on a throwaway CairoMakie figure built with the same title/xlabel/font
# parameters as the real axis (font metrics and Makie's own layout solver
# drive this, not a hand-tuned formula). Rows are laid out with Makie's
# default Auto sizing (equal division of the figure height) rather than
# Fixed sizes: Fixed rows do not leave room for a title's protrusion, which
# then renders outside the figure canvas entirely.
function _legend_row_height_px(labels_vec, legendsize, has_title, title_str,
                               titlesize, has_xlabel, xlabel_str, xlsize)
    isempty(labels_vec) && return 0
    CairoMakie.activate!()
    h = try
        fig = Figure(size=(200, 1000))
        ax = Axis(fig[1, 1]; title=has_title ? title_str : "",
                  titlesize=titlesize, titlefont=TITLE_FONT)
        if has_xlabel
            ax.xlabel = xlabel_str
            ax.xlabelsize = xlsize
        end
        for (i, l) in pairs(labels_vec)
            lines!(ax, [0.0, 1.0], [Float64(i), Float64(i) + 1]; label=l)
        end
        leg = axislegend(ax; position=:rt, labelsize=legendsize)
        notify(fig.scene.viewport)
        prot = ax.layoutobservables.protrusions[]
        content_h = leg.layoutobservables.computedbbox[].widths[2]
        prot.top + content_h + prot.bottom
    finally
        GLMakie.activate!()
    end
    return round(Int, h)
end

# `_show_interactive` lays the plot row out with Auto sizing alongside the
# controls row it adds, so requesting `figsize` does not guarantee each
# channel's axis panel actually gets the height `_legend_row_height_px`
# assumed: GridLayout can shrink the plot row below the requested height,
# and a top-right-anchored legend (sized for the *requested* panel height)
# then overflows past the axis's own bottom edge — the legend isn't
# clipped, it just extends below the x-axis line. That squeeze is pure
# GridLayoutBase layout math, independent of the rendering backend, so the
# actual overflow (if any) can be measured directly and cheaply with
# CairoMakie by replicating `_show_interactive`'s construction (same calls,
# same builder) without the final display step, then comparing each
# channel's own axis-bottom against its legend-bottom — the exact geometric
# condition that must hold, rather than an indirect proxy. Extra window
# height is shared equally across the `n` stacked channels (matching how
# plot_grid's inner rows divide space), so the worst channel's overflow
# must be multiplied by `n` to fully close the gap.
function _predict_row1_deficit(builder, target_h, window_w, n)
    prev_backend = Makie.current_backend()
    CairoMakie.activate!()
    deficit = try
        fig_probe = Figure(; size=(window_w, target_h + _CONTROLS_HEIGHT))
        plot_grid = GridLayout(fig_probe[1, 1])
        artifacts = builder(plot_grid)
        axes_list = _extract_axes(artifacts)
        _add_controls!(fig_probe, axes_list, builder, "__legend_probe__";
                       figsize=(window_w, target_h))
        legends = [p for p in fig_probe.content if p isa Legend]
        max_overflow = 0.0
        for ax in axes_list
            ax_bbox = ax.layoutobservables.computedbbox[]
            ax_top = ax_bbox.origin[2] + ax_bbox.widths[2]
            isempty(legends) && continue
            # Every channel gets its own axislegend anchored at the top of
            # its axis, so its top edge sits closest to that axis's own top
            # edge — the most reliable pairing when several channels (each
            # sharing the same x-column) are stacked vertically.
            leg = argmin(l -> abs((l.layoutobservables.computedbbox[].origin[2] +
                                   l.layoutobservables.computedbbox[].widths[2]) - ax_top),
                        legends)
            leg_bottom = leg.layoutobservables.computedbbox[].origin[2]
            max_overflow = max(max_overflow, ax_bbox.origin[2] - leg_bottom)
        end
        max_overflow * n
    finally
        prev_backend === GLMakie && GLMakie.activate!()
    end
    return ceil(Int, deficit)
end

function plotx(X, Y...; xlabel="time [s]", ylabels=nothing, labels=nothing,
               xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
               fig="", title="", ysize=nothing, xsize=nothing, labelsize=16,
               legend_position=:auto, output_folder="output", yzoom=1.0,
               disp=false, new_screen=true, legendsize=16, titlesize=18,
               xscale::Symbol=:identity, grid=true, xticks=nothing)
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(collect(X), Y, labels, xlabel, ylabels, title, ylsize,
                         yzoom, xlims, ylims, ann, scatter, fig, 2, xlsize,
                         legend_position, legendsize, titlesize, xscale, grid, "", xticks, nothing)
    if disp
        n = length(Y)
        base_row_h = round(Int, 2 * yzoom * 96)
        needed_hs = Vector{Int}(undef, n)
        row_bumped = Vector{Bool}(undef, n)
        per_row_h = base_row_h
        for (i, y) in pairs(Y)
            lbl = (!isnothing(labels) && i <= length(labels)) ? labels[i] : nothing
            needed_hs[i] = _legend_row_height_px(_channel_legend_labels(y, lbl), legendsize,
                i == 1, title, titlesize, i == n, xlabel, xlsize)
            row_bumped[i] = needed_hs[i] > base_row_h
            per_row_h = max(per_row_h, needed_hs[i])
        end
        size_px = (round(Int, 8 * 96), max(240, n * per_row_h))
        xscale_sym = xscale::Symbol
        builder = function(layout)
            axes_arr = Axis[]
            for (i, y) in pairs(Y)
                ax = Axis(layout[i, 1]; ylabelsize=ylsize,
                          title=(i == 1) ? title : "",
                          titlesize=titlesize,
                          titlefont=TITLE_FONT,
                          xscale=_xscale_func(xscale))
                if (xscale_sym::Symbol) == :log10
                    ax.xtickformat = xs -> [string(round(x, digits=1)) for x in xs]
                end
                if !isnothing(xticks)
                    ax.xticks = xticks
                end
                ax.xgridvisible = grid
                ax.ygridvisible = grid
                if !isnothing(ylabels) && i <= length(ylabels)
                    ax.ylabel = string(ylabels[i])
                end
                push!(axes_arr, ax)
                lbl = nothing
                if !isnothing(labels) && i <= length(labels)
                    lbl = labels[i]
                end
                added_label = false
                ax_yvecs = Vector{Float64}[]
                for (j, yy) in pairs(y)
                    if yy isa AbstractVector
                        l = ""
                        if !isnothing(lbl) && lbl isa AbstractVector &&
                           j <= length(lbl)
                            l = string(lbl[j])
                        end
                        if l != ""
                            lines!(ax, X, yy; linewidth=LINE_WIDTH, label=l)
                            added_label = true
                        else
                            lines!(ax, X, yy; linewidth=LINE_WIDTH)
                        end
                        push!(ax_yvecs, Float64.(yy))
                    else
                        l = isnothing(lbl) ? "" :
                            (lbl isa AbstractVector ? "" : string(lbl))
                        if l != ""
                            lines!(ax, X, y; linewidth=LINE_WIDTH, label=l)
                            added_label = true
                        else
                            lines!(ax, X, y; linewidth=LINE_WIDTH)
                        end
                        push!(ax_yvecs, Float64.(y))
                        break
                    end
                end
                xlims!(ax, first(X), last(X))
                pos = (row_bumped[i] && legend_position === :auto) ? :rt :
                      _resolve_corner(legend_position, X, ax_yvecs)
                added_label && axislegend(ax; position=pos, labelsize=legendsize)
            end
            if length(axes_arr) > 1
                linkxaxes!(axes_arr...)
            end
            for i in 1:length(axes_arr)-1
                hidexdecorations!(axes_arr[i]; grid=false, ticks=false)
            end
            if !isempty(axes_arr)
                axes_arr[end].xlabel = string(xlabel)
                axes_arr[end].xlabelsize = xlsize
            end
            return (; axes=axes_arr)
        end
        if any(>(0), needed_hs)
            deficit = _predict_row1_deficit(builder, size_px[2], size_px[1], n)
            display_px = (size_px[1], size_px[2] + deficit)
            _show_interactive(builder; figsize=display_px, fig_name=fig,
                              output_folder, new_screen)
            # Exports have no competing controls row (see _export_figure), so
            # they never suffer this squeeze — keep them at the precise
            # content size rather than inheriting the padded window size.
            _LAST_FIGSIZE[] = size_px
        else
            _show_interactive(builder; figsize=size_px, fig_name=fig,
                              output_folder, new_screen)
        end
    end
    return plotx_struct
end
