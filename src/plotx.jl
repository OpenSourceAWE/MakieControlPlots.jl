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

# Actual pixel height Makie needs to render an axislegend with these labels,
# measured on a throwaway CairoMakie figure (font metrics, not axis size,
# drive this, so a tiny probe figure is enough).
function _legend_content_height_px(labels_vec, legendsize)
    isempty(labels_vec) && return 0
    CairoMakie.activate!()
    h = try
        fig = Figure(size=(200, 400))
        ax = Axis(fig[1, 1])
        for (i, l) in pairs(labels_vec)
            lines!(ax, [0.0, 1.0], [Float64(i), Float64(i) + 1]; label=l)
        end
        leg = axislegend(ax; labelsize=legendsize)
        notify(fig.scene.viewport)
        leg.layoutobservables.computedbbox[].widths[2]
    finally
        GLMakie.activate!()
    end
    return round(Int, h)
end

# Extra pixels a row needs beyond the raw legend content height, to account
# for the axis's own title band and top/bottom panel padding. Rows are laid
# out with Makie's default Auto sizing (equal division of the figure height)
# rather than Fixed sizes: Fixed rows do not leave room for a title's
# protrusion, which then renders outside the figure canvas entirely.
_legend_row_overhead(has_title::Bool, titlesize) =
    (has_title ? titlesize + 20 : 0) + 20

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
        row_bumped = Vector{Bool}(undef, n)
        per_row_h = base_row_h
        for (i, y) in pairs(Y)
            lbl = (!isnothing(labels) && i <= length(labels)) ? labels[i] : nothing
            content_h = _legend_content_height_px(_channel_legend_labels(y, lbl), legendsize)
            needed_h = content_h > 0 ?
                content_h + _legend_row_overhead(i == 1, titlesize) : 0
            row_bumped[i] = needed_h > base_row_h
            per_row_h = max(per_row_h, needed_h)
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
        _show_interactive(builder; figsize=size_px, fig_name=fig,
                          output_folder, new_screen)
    end
    return plotx_struct
end
