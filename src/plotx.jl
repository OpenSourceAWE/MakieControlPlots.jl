function plotx(X, Y...; xlabel="time [s]", ylabels=nothing, labels=nothing,
               xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
               fig="", title="", ysize=14, yzoom=1.0, disp=true)
    plotx_struct = PlotX(collect(X), Y, labels, xlabel, ylabels, title, ysize,
                         yzoom, xlims, ylims, ann, scatter, fig, 2)
    if disp
        n = length(Y)
        size_px = (round(Int, 8 * 96),
                   max(240, round(Int, n * 2 * yzoom * 96)))
        builder = function(layout)
            axes_arr = Axis[]
            for (i, y) in pairs(Y)
                ax = Axis(layout[i, 1]; ylabelsize=ysize)
                if !isnothing(ylabels) && i <= length(ylabels)
                    ax.ylabel = string(ylabels[i])
                end
                push!(axes_arr, ax)
                lbl = nothing
                if !isnothing(labels) && i <= length(labels)
                    lbl = labels[i]
                end
                added_label = false
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
                    else
                        l = isnothing(lbl) ? "" :
                            (lbl isa AbstractVector ? "" : string(lbl))
                        if l != ""
                            lines!(ax, X, y; label=l)
                            added_label = true
                        else
                            lines!(ax, X, y)
                        end
                        break
                    end
                end
                xlims!(ax, first(X), last(X))
                added_label && axislegend(ax)
            end
            if length(axes_arr) > 1
                linkxaxes!(axes_arr...)
            end
            for i in 1:length(axes_arr)-1
                hidexdecorations!(axes_arr[i]; grid=false, ticks=false)
            end
            if !isempty(axes_arr)
                axes_arr[end].xlabel = string(xlabel)
            end
            if title != ""
                Label(layout[0, 1], string(title); fontsize=14,
                      tellwidth=false)
            end
            return (; axes=axes_arr)
        end
        _show_interactive(builder; figsize=size_px, fig_name=fig)
    end
    return plotx_struct
end
