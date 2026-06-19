function plotxy(X, Y; xlabel="", ylabel="", title="", xlims=nothing,
                ylims=nothing, ann=nothing, scatter=false, fig="",
                ysize=nothing, xsize=nothing, labelsize=16,
                output_folder="output", disp=false, new_screen=true,
                titlesize=16, legendsize=16, xscale=:identity, grid=true)
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(X, Y, nothing, xlabel, ylabel, title, ylsize, nothing,
                         xlims, ylims, ann, scatter, fig, 3, xlsize, :auto, legendsize, titlesize, xscale, grid, "", nothing)
    if disp
        builder = function(layout)
            ax = Axis(layout[1, 1]; xlabel=string(xlabel),
                      ylabel=string(ylabel), ylabelsize=ylsize,
                      xlabelsize=xlsize, xscale=_xscale_func(xscale),
                      title=title,
                      titlesize=titlesize,
                      titlefont=TITLE_FONT)
            if xscale == :log10
                ax.xtickformat = xs -> [string(round(x, digits=1)) for x in xs]
            end
            ax.xgridvisible = grid
            ax.ygridvisible = grid
            lines!(ax, X, Y; linewidth=LINE_WIDTH)
            scatter && scatter!(ax, X, Y; color=:red, markersize=8)
            isnothing(xlims) || xlims!(ax, xlims[1], xlims[2])
            isnothing(ylims) || ylims!(ax, ylims[1], ylims[2])
            if !isnothing(ann)
                text!(ax, ann[1], ann[2]; text=string(ann[3]), fontsize=14)
            end
            return (; axes=[ax])
        end
        _show_interactive(builder; figsize=(576, 576), fig_name=fig,
                          output_folder, new_screen)
    end
    return plotx_struct
end
