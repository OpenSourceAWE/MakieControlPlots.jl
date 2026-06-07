function plotx(X, Y...; xlabel="time [s]", ylabels=nothing, labels=nothing,
               xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
               fig="", title="", ysize=nothing, xsize=nothing, labelsize=20,
               legend_position=:auto, output_folder="output", yzoom=1.0,
               disp=false, new_screen=true)
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(collect(X), Y, labels, xlabel, ylabels, title, ylsize,
                         yzoom, xlims, ylims, ann, scatter, fig, 2, xlsize,
                         legend_position)
    if disp
        n = length(Y)
        size_px = (round(Int, 8 * 96),
                   max(240, round(Int, n * 2 * yzoom * 96)))
        builder = function(layout)
            axes_arr = Axis[]
            for (i, y) in pairs(Y)
                ax = Axis(layout[i, 1]; ylabelsize=ylsize)
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
                            lines!(ax, X, yy; label=l)
                            added_label = true
                        else
                            lines!(ax, X, yy)
                        end
                        push!(ax_yvecs, Float64.(yy))
                    else
                        l = isnothing(lbl) ? "" :
                            (lbl isa AbstractVector ? "" : string(lbl))
                        if l != ""
                            lines!(ax, X, y; label=l)
                            added_label = true
                        else
                            lines!(ax, X, y)
                        end
                        push!(ax_yvecs, Float64.(y))
                        break
                    end
                end
                xlims!(ax, first(X), last(X))
                added_label && axislegend(ax;
                    position=_resolve_corner(legend_position, X, ax_yvecs))
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
            if title != ""
                Label(layout[0, 1], string(title); fontsize=14,
                      tellwidth=false)
            end
            return (; axes=axes_arr)
        end
        _show_interactive(builder; figsize=size_px, fig_name=fig,
                          output_folder, new_screen)
    end
    return plotx_struct
end
