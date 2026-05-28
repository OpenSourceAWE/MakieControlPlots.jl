function plotxy(X, Y; xlabel="", ylabel="", xlims=nothing, ylims=nothing,
                ann=nothing, scatter=false, fig="", ysize=14, disp=true)
    plotx_struct = PlotX(X, Y, nothing, xlabel, ylabel, ysize, nothing,
                         xlims, ylims, ann, scatter, fig, 3)
    if disp
        builder = function(layout)
            ax = Axis(layout[1, 1]; xlabel=string(xlabel),
                      ylabel=string(ylabel), ylabelsize=ysize)
            lines!(ax, X, Y)
            scatter && scatter!(ax, X, Y; color=:red, markersize=8)
            isnothing(xlims) || xlims!(ax, xlims[1], xlims[2])
            isnothing(ylims) || ylims!(ax, ylims[1], ylims[2])
            if !isnothing(ann)
                text!(ax, ann[1], ann[2]; text=string(ann[3]), fontsize=14)
            end
            return (; axes=[ax])
        end
        _show_interactive(builder; figsize=(576, 576), fig_name=fig)
    end
    return plotx_struct
end
