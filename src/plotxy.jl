"""
    plotxy(X, Y; xlabel="", ylabel="", title="", xlims=nothing,
           ylims=nothing, ann=nothing, scatter=false, fig="",
           ysize=nothing, xsize=nothing, labelsize=16,
           output_folder="output", disp=false, new_screen=true,
           titlesize=18, legendsize=16, xscale=:identity, grid=true,
           xticks=nothing, aspect=nothing, linestyle=nothing)

Create an XY plot of `Y` versus `X`, i.e. a parametric plot where `X` is not
necessarily monotonically increasing (useful for plotting paths/trajectories).

Pass `aspect=:equal` to give the X and Y axes equal scaling (matplotlib's
`ax.set_aspect("equal")`), useful when distances along X and Y must look the
same. `linestyle` sets the line style of the curve (e.g. `:solid`, `:dash`,
`:dot`).

    plotxy(Xs::AbstractVector{<:AbstractVector}, Ys::AbstractVector{<:AbstractVector};
           xlabel="", ylabel="", title="", xlims=nothing,
           ylims=nothing, ann=nothing, scatter=false, fig="",
           ysize=nothing, xsize=nothing, labelsize=16,
           output_folder="output", disp=false, new_screen=true,
           titlesize=18, legendsize=16, xscale=:identity, grid=true,
           xticks=nothing, aspect=nothing, legend=nothing, linestyle=nothing)

Plot several XY series in one plot; `Xs` and `Ys` must have the same length,
one vector per series. The optional `legend` parameter takes a vector of
labels, one per series; series without a label are not added to the legend.
The optional `linestyle` parameter can be a single line style applied to all
series, or a vector of line styles, one per series.
"""
function plotxy(X::AbstractVector{<:Number}, Y::AbstractVector{<:Number}; xlabel="", ylabel="", title="", xlims=nothing,
                ylims=nothing, ann=nothing, scatter=false, fig="",
                ysize=nothing, xsize=nothing, labelsize=16,
                output_folder="output", disp=false, new_screen=true,
                titlesize=18, legendsize=16, xscale::Symbol=:identity, grid=true,
                xticks=nothing, aspect::Union{Nothing, Symbol}=nothing,
                linestyle=nothing)
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(X, Y, nothing, xlabel, ylabel, title, ylsize, nothing,
                         xlims, ylims, ann, scatter, fig, 3, xlsize, :auto, legendsize, titlesize, xscale, grid, "", xticks, aspect, linestyle)
    if disp
        xscale_sym = xscale::Symbol
        builder = function(layout)
            ax = Axis(layout[1, 1]; xlabel=string(xlabel),
                      ylabel=string(ylabel), ylabelsize=ylsize,
                      xlabelsize=xlsize, xscale=_xscale_func(xscale),
                      title=title,
                      titlesize=titlesize,
                      titlefont=TITLE_FONT,
                      aspect=aspect == :equal ? DataAspect() : nothing)
            if (xscale_sym::Symbol) == :log10
                ax.xtickformat = xs -> [string(round(x, digits=1)) for x in xs]
            end
            if !isnothing(xticks)
                ax.xticks = xticks
            end
            ax.xgridvisible = grid
            ax.ygridvisible = grid
            lines!(ax, X, Y; linewidth=LINE_WIDTH, linestyle=linestyle)
            scatter && scatter!(ax, X, Y; color=:red, markersize=8)
            isnothing(xlims) || xlims!(ax, xlims[1], xlims[2])
            isnothing(ylims) || ylims!(ax, ylims[1], ylims[2])
            if !isnothing(ann)
                text!(ax, ann[1], ann[2]; text=string(ann[3]), fontsize=14)
            end
            return (; axes=[ax])
        end
        _show_interactive(builder; figsize=(640, 576), fig_name=fig,
                          output_folder, new_screen)
    end
    return plotx_struct
end

function _linestyle_at(linestyle, i)
    isnothing(linestyle) && return nothing
    linestyle isa AbstractVector || return linestyle
    i <= length(linestyle) ? linestyle[i] : nothing
end

function plotxy(Xs::AbstractVector{<:AbstractVector},
                Ys::AbstractVector{<:AbstractVector};
                xlabel="", ylabel="", title="", xlims=nothing,
                ylims=nothing, ann=nothing, scatter=false, fig="",
                ysize=nothing, xsize=nothing, labelsize=16,
                output_folder="output", disp=false, new_screen=true,
                titlesize=18, legendsize=16, xscale::Symbol=:identity, grid=true,
                xticks=nothing, aspect::Union{Nothing, Symbol}=nothing,
                legend=nothing, linestyle=nothing)
    if length(Xs) != length(Ys)
        error("Number of X series ($(length(Xs))) must match number of Y series ($(length(Ys)))")
    end
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(Xs, Ys, legend, xlabel, ylabel, title, ylsize, nothing,
                         xlims, ylims, ann, scatter, fig, 3, xlsize, :auto, legendsize, titlesize, xscale, grid, "", xticks, aspect, linestyle)
    if disp
        xscale_sym = xscale::Symbol
        builder = function(layout)
            ax = Axis(layout[1, 1]; xlabel=string(xlabel),
                      ylabel=string(ylabel), ylabelsize=ylsize,
                      xlabelsize=xlsize, xscale=_xscale_func(xscale),
                      title=title,
                      titlesize=titlesize,
                      titlefont=TITLE_FONT,
                      aspect=aspect == :equal ? DataAspect() : nothing)
            if (xscale_sym::Symbol) == :log10
                ax.xtickformat = xs -> [string(round(x, digits=1)) for x in xs]
            end
            if !isnothing(xticks)
                ax.xticks = xticks
            end
            ax.xgridvisible = grid
            ax.ygridvisible = grid
            has_label = false
            for (i, (X, Y)) in enumerate(zip(Xs, Ys))
                lbl = ""
                if !isnothing(legend) && i <= length(legend) && !isnothing(legend[i])
                    lbl = string(legend[i])
                end
                ls = _linestyle_at(linestyle, i)
                if lbl != ""
                    lines!(ax, X, Y; linewidth=LINE_WIDTH, linestyle=ls, label=lbl)
                    has_label = true
                else
                    lines!(ax, X, Y; linewidth=LINE_WIDTH, linestyle=ls)
                end
                if scatter
                    scatter!(ax, X, Y; color=:red, markersize=8)
                end
            end
            if has_label
                axislegend(ax; labelsize=legendsize)
            end
            isnothing(xlims) || xlims!(ax, xlims[1], xlims[2])
            isnothing(ylims) || ylims!(ax, ylims[1], ylims[2])
            if !isnothing(ann)
                text!(ax, ann[1], ann[2]; text=string(ann[3]), fontsize=14)
            end
            return (; axes=[ax])
        end
        _show_interactive(builder; figsize=(640, 576), fig_name=fig,
                          output_folder, new_screen)
    end
    return plotx_struct
end
