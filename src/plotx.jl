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
        leg = axislegend(ax; position=:rt, _legend_style(legendsize)...)
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
        # The builder reports each channel's own axislegend (`nothing` for a
        # channel that got none), so a legend is paired with the axis that
        # owns it by construction. Recovering that pairing geometrically —
        # scraping `fig_probe.content` for legends and asking which row band
        # a legend's top edge falls into — is not reliable: an axislegend is
        # anchored flush with the top of its axis, so its top edge coincides
        # with the band boundary and sub-pixel layout rounding can push it
        # into the neighbouring row's band, leaving one row with two legends
        # and its neighbour with none.
        legends = _extract_legends(artifacts, length(axes_list))
        max_overflow = 0.0
        for (i, ax) in pairs(axes_list)
            leg = legends[i]
            isnothing(leg) && continue
            ax_bbox = ax.layoutobservables.computedbbox[]
            leg_bottom = leg.layoutobservables.computedbbox[].origin[2]
            max_overflow = max(max_overflow, ax_bbox.origin[2] - leg_bottom)
        end
        max_overflow * n
    finally
        prev_backend === GLMakie && GLMakie.activate!()
    end
    return ceil(Int, deficit)
end

# A `ylabels` entry that is itself a 2-element vector or tuple marks that
# channel as a twin-axis panel: its last curve is drawn against a second y
# axis on the right labeled `ylabels[i][2]`, the earlier ones against the
# left axis labeled `ylabels[i][1]`. This mirrors the left/right convention
# `plot(X, Y1, Y2)` already uses for `ylabels`, so it needs no new keyword —
# and `PlotX` structs saved by older versions keep round-tripping unchanged,
# since the marker rides along in a field that already exists.
_is_twin_ylabel(l) = (l isa AbstractVector || l isa Tuple) && length(l) == 2

# `linestyle`, one entry per channel (mirroring `labels`/`ylabels`): that
# entry is a single style applied to every curve in the channel, or, for a
# multi-curve channel, a vector of per-curve styles. A missing/`nothing`
# entry keeps Makie's solid default.
_channel_linestyle(style_all, i) =
    (!isnothing(style_all) && i <= length(style_all)) ? style_all[i] : nothing
_curve_linestyle(style, j) =
    isnothing(style) ? nothing : (style isa AbstractVector ?
        (j <= length(style) ? style[j] : nothing) : style)

# `legend_position`, one entry per channel, same convention as `labels`/
# `linestyle`: a vector gives one corner (`:auto`, `:lt`, `:rt`, `:lb`, `:rb`)
# per channel; a bare symbol (the default `:auto`) applies to every channel,
# unchanged from before per-channel positions existed.
_channel_legend_position(pos_all, i) =
    pos_all isa AbstractVector ? (i <= length(pos_all) ? pos_all[i] : :auto) : pos_all

# `color`, one entry per channel, same convention as `linestyle`: a single
# color applies to every curve in that channel, or a vector gives one color
# per curve. A missing entry — the whole channel, a `nothing` curve entry, or
# one past the end of the vector — falls back to the default cycle color, so
# only the curves that need an explicit color name one. Render-only, like
# `disp`/`new_screen`/`output_folder`: not one of `PlotX`'s persisted fields,
# so a saved-and-reloaded plot redraws with the default cycle.
_channel_color(color_all, i) =
    (!isnothing(color_all) && i <= length(color_all)) ? color_all[i] : nothing
_curve_color(color, j) =
    isnothing(color) ? _cycle_color(j) :
    (color isa AbstractVector ?
        ((j <= length(color) && !isnothing(color[j])) ? color[j] : _cycle_color(j)) :
        color)

# One channel's curves as a plain vector, whether it was passed as a single
# time series, a vector of them, or a tuple of them.
_channel_curves(y) = y isa AbstractVector{<:Number} ? Any[y] : collect(y)

# Makie's color cycler runs per axis, so a twin panel's right-hand curve would
# restart the cycle and repeat the color of the first left-hand curve. Colors
# are therefore assigned explicitly from the default palette, indexed across
# the channel as a whole — which reproduces exactly what a single-axis channel
# gets automatically.
_cycle_color(j::Int) = Makie.wong_colors()[mod1(j, length(Makie.wong_colors()))]

function plotx(X, Y...; xlabel="time [s]", ylabels=nothing, labels=nothing,
               xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
               fig="", title="", ysize=nothing, xsize=nothing, labelsize=16,
               legend_position=:auto, output_folder="output", yzoom=1.0,
               disp=false, new_screen=true, legendsize=16, titlesize=18,
               xscale::Symbol=:identity, grid=true, xticks=nothing, rowgap=18,
               linestyle=nothing, color=nothing)
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(collect(X), Y, labels, xlabel, ylabels, title, ylsize,
                         yzoom, xlims, ylims, ann, scatter, fig, 2, xlsize,
                         legend_position, legendsize, titlesize, xscale, grid, "", xticks, nothing, linestyle, rowgap)
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
            twins_arr = Axis[]
            legends_arr = Union{Legend,Nothing}[]
            for (i, y) in pairs(Y)
                ylbl = (!isnothing(ylabels) && i <= length(ylabels)) ?
                       ylabels[i] : nothing
                curves = _channel_curves(y)
                # A twin panel needs a curve for each of its two axes; with
                # only one, the request is silently the ordinary single-axis
                # channel it has to be, labeled by the left-hand entry.
                twin = _is_twin_ylabel(ylbl) && length(curves) > 1
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
                if !isnothing(ylbl)
                    ax.ylabel = string(_is_twin_ylabel(ylbl) ? ylbl[1] : ylbl)
                end
                push!(axes_arr, ax)
                lbl = nothing
                if !isnothing(labels) && i <= length(labels)
                    lbl = labels[i]
                end
                ls = _channel_linestyle(linestyle, i)
                lp = _channel_legend_position(legend_position, i)
                cc = _channel_color(color, i)
                if twin
                    ax2 = Axis(layout[i, 1]; ylabel=string(ylbl[2]),
                               ylabelsize=ylsize, yaxisposition=:right,
                               backgroundcolor=RGBAf(0, 0, 0, 0),
                               xscale=_xscale_func(xscale))
                    if (xscale_sym::Symbol) == :log10
                        ax2.xtickformat = xs -> [string(round(x, digits=1)) for x in xs]
                    end
                    if !isnothing(xticks)
                        ax2.xticks = xticks
                    end
                    hidespines!(ax2)
                    hidexdecorations!(ax2)
                    # The left axis draws the panel's grid: a second set of
                    # gridlines, at the right axis' own tick positions, would
                    # not line up with it.
                    ax2.xgridvisible = false
                    ax2.ygridvisible = false
                    push!(twins_arr, ax2)
                    lns = Any[]
                    # Not `String[]`: `lbl[j]` is usually a `LaTeXString`, and
                    # pushing into a concretely `Vector{String}` converts each
                    # entry down to a plain `String`, silently dropping the
                    # type Makie's Legend needs to render it as math instead
                    # of literal `$...$` text.
                    leg_labels = []
                    ax_yvecs = Vector{Float64}[]
                    for (j, yy) in pairs(curves)
                        target = (j == length(curves)) ? ax2 : ax
                        ln = lines!(target, X, yy; linewidth=LINE_WIDTH,
                                    color=_curve_color(cc, j),
                                    linestyle=_curve_linestyle(ls, j))
                        l = (lbl isa AbstractVector && j <= length(lbl)) ?
                            string(lbl[j]) : ""
                        if l != ""
                            push!(lns, ln)
                            push!(leg_labels, l)
                        end
                        # Both axes carry their own scale, so the legend has to
                        # pick its corner from the curves' shapes, not values.
                        push!(ax_yvecs, _normalize01(yy))
                    end
                    # The right axis' label and ticks take their curve's color,
                    # as in `plot(X, Y1, Y2)`; the left ones only when a single
                    # curve makes the mapping unambiguous.
                    ax2.ylabelcolor = ax2.yticklabelcolor = _cycle_color(length(curves))
                    if length(curves) == 2
                        ax.ylabelcolor = ax.yticklabelcolor = _cycle_color(1)
                    end
                    xlims!(ax, first(X), last(X))
                    xlims!(ax2, first(X), last(X))
                    if isempty(lns)
                        push!(legends_arr, nothing)
                    else
                        pos = (row_bumped[i] && lp === :auto) ? :rt :
                              _resolve_corner(lp, X, ax_yvecs)
                        leg_ha, leg_va = _corner_align(pos)
                        # One legend for the whole panel, built by hand: an
                        # `axislegend` only sees the plots of the axis it is
                        # attached to, and these curves live on two.
                        push!(legends_arr,
                              Legend(layout[i, 1], lns, leg_labels;
                                     tellwidth=false, tellheight=false,
                                     halign=leg_ha, valign=leg_va,
                                     margin=(10, 10, 10, 10),
                                     _legend_style(legendsize)...))
                    end
                    continue
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
                        curve_ls = _curve_linestyle(ls, j)
                        # Only channels that opt into `color` get an explicit
                        # one; others keep Makie's own per-axis auto-cycle.
                        curve_kw = isnothing(cc) ? (;) : (; color = _curve_color(cc, j))
                        if l != ""
                            lines!(ax, X, yy; linewidth=LINE_WIDTH, label=l, linestyle=curve_ls, curve_kw...)
                            added_label = true
                        else
                            lines!(ax, X, yy; linewidth=LINE_WIDTH, linestyle=curve_ls, curve_kw...)
                        end
                        push!(ax_yvecs, Float64.(yy))
                    else
                        l = isnothing(lbl) ? "" :
                            (lbl isa AbstractVector ? "" : string(lbl))
                        curve_ls = _curve_linestyle(ls, 1)
                        curve_kw = isnothing(cc) ? (;) : (; color = _curve_color(cc, 1))
                        if l != ""
                            lines!(ax, X, y; linewidth=LINE_WIDTH, label=l, linestyle=curve_ls, curve_kw...)
                            added_label = true
                        else
                            lines!(ax, X, y; linewidth=LINE_WIDTH, linestyle=curve_ls, curve_kw...)
                        end
                        push!(ax_yvecs, Float64.(y))
                        break
                    end
                end
                xlims!(ax, first(X), last(X))
                pos = (row_bumped[i] && lp === :auto) ? :rt :
                      _resolve_corner(lp, X, ax_yvecs)
                push!(legends_arr,
                      added_label ? axislegend(ax; position=pos, _legend_style(legendsize)...) :
                      nothing)
            end
            rowgap!(layout, rowgap)
            # Twin axes share the stack's x axis like any other panel, so they
            # pan and zoom with it rather than drifting out of register.
            all_axes = vcat(axes_arr, twins_arr)
            if length(all_axes) > 1
                linkxaxes!(all_axes...)
            end
            for i in 1:length(axes_arr)-1
                hidexdecorations!(axes_arr[i]; grid=false, ticks=false)
            end
            if !isempty(axes_arr)
                axes_arr[end].xlabel = string(xlabel)
                axes_arr[end].xlabelsize = xlsize
            end
            # Channel axes first, twins after: the interactive controls act on
            # every axis reported here, while `_extract_legends` pairs the
            # first `length(legends_arr)` of them with the per-channel legends.
            return (; axes=all_axes, legends=legends_arr)
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
