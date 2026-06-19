function plot(Y::AbstractVector{<:Number}; xlabel="", ylabel="", title="",
              fig="", ysize=nothing, xsize=nothing, labelsize=16,
              output_folder="output", disp=false, new_screen=true,
              titlesize=18, legendsize=16, xscale=:identity, grid=true, label="",
              xticks=nothing)
    X = 1:length(Y)
    return plot(X, Y; xlabel, ylabel, title, fig, ysize, xsize, labelsize,
                output_folder, disp, new_screen, titlesize, legendsize,
                xscale, grid, label, xticks)
end

function plot(X, Y::AbstractVector{<:Number}; xlabel="", ylabel="", title="",
              xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
              fig="", ysize=nothing, xsize=nothing, labelsize=16,
              output_folder="output", disp=false, new_screen=true,
              titlesize=18, legendsize=16, xscale=:identity, grid=true, label="",
              xticks=nothing)
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(X, Y, nothing, xlabel, ylabel, title, ylsize, nothing,
                         xlims, ylims, ann, scatter, fig, 1, xlsize, :auto, legendsize, titlesize, xscale, grid, label, xticks)
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
            if !isnothing(xticks)
                ax.xticks = xticks
            end
            ax.xgridvisible = grid
            ax.ygridvisible = grid
            lines!(ax, X, Y; linewidth=LINE_WIDTH, label=isempty(label) ? nothing : label)
            scatter && scatter!(ax, X, Y; color=:red, markersize=8)
            if isnothing(xlims)
                xlims!(ax, first(X), last(X))
            else
                xlims!(ax, xlims[1], xlims[2])
            end
            isnothing(ylims) || ylims!(ax, ylims[1], ylims[2])
            if !isnothing(ann)
                text!(ax, ann[1], ann[2]; text=string(ann[3]), fontsize=14)
            end
            if !isempty(label)
                axislegend(ax; labelsize=legendsize)
            end
            return (; axes=[ax])
        end
        _show_interactive(builder; fig_name=fig, output_folder, new_screen)
    end
    return plotx_struct
end

function plot(X, Ys::AbstractVector{<:Union{AbstractVector, Tuple}};
              xlabel="", ylabel="", title="", labels=nothing, xlims=nothing,
              ylims=nothing, ann=nothing, scatter=false, fig="",
              ysize=nothing, xsize=nothing, labelsize=16,
              legend_position=:auto, output_folder="output", disp=false,
              new_screen=true, legendsize=16, titlesize=18, xscale=:identity, grid=true, label="",
              xticks=nothing)
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(X, Ys, labels, xlabel, ylabel, title, ylsize, nothing,
                         xlims, ylims, ann, scatter, fig, 4, xlsize,
                         legend_position, legendsize, titlesize, xscale, grid, label, xticks)
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
            if !isnothing(xticks)
                ax.xticks = xticks
            end
            ax.xgridvisible = grid
            ax.ygridvisible = grid
            any_label = false
            legend_yvecs = Vector{Float64}[]
            for (i, YT) in pairs(Ys)
                lbl = ""
                if !isnothing(labels) && i <= length(labels) &&
                   !isnothing(labels[i])
                    lbl = string(labels[i])
                end
                if YT isa Tuple
                    Y, Yerr = YT
                    if isnothing(Yerr)
                        if lbl != ""
                            lines!(ax, X, Y; linewidth=LINE_WIDTH, label=lbl); any_label = true
                        else
                            lines!(ax, X, Y; linewidth=LINE_WIDTH)
                        end
                    else
                        errorbars!(ax, X, Y, Yerr; whiskerwidth=10)
                        if lbl != ""
                            lines!(ax, X, Y; linewidth=LINE_WIDTH, label=lbl); any_label = true
                        else
                            lines!(ax, X, Y; linewidth=LINE_WIDTH)
                        end
                    end
                    scatter && scatter!(ax, X, Y; color=:red, markersize=8)
                else
                    Y = YT
                    if lbl != ""
                        lines!(ax, X, Y; linewidth=LINE_WIDTH, label=lbl); any_label = true
                    else
                        lines!(ax, X, Y; linewidth=LINE_WIDTH)
                    end
                    scatter && scatter!(ax, X, Y; color=:red, markersize=8)
                end
                push!(legend_yvecs, Float64.(Y))
            end
            if !isempty(label)
                lines!(ax, X, Ys[1]; linewidth=LINE_WIDTH, label=label)
                any_label = true
            end
            isnothing(xlims) || xlims!(ax, xlims[1], xlims[2])
            isnothing(ylims) || ylims!(ax, ylims[1], ylims[2])
            if !isnothing(ann)
                text!(ax, ann[1], ann[2]; text=string(ann[3]), fontsize=14)
            end
            any_label && axislegend(ax;
                position=_resolve_corner(legend_position, X, legend_yvecs),
                labelsize=legendsize)
            return (; axes=[ax])
        end
        _show_interactive(builder; fig_name=fig, output_folder, new_screen)
    end
    return plotx_struct
end

function plot(X, Y1::AbstractVector{<:Number}, Y2::AbstractVector{<:Number};
              xlabel="", ylabels=["", ""], title="", labels=["", ""],
              xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
              fig="", ysize=nothing, xsize=nothing, labelsize=16,
              legend_position=:auto, output_folder="output", disp=false,
              new_screen=true, legendsize=16, titlesize=18, xscale=:identity, grid=true, label="",
              xticks=nothing)
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(X, [Y1, Y2], labels, xlabel, ylabels, title, ylsize,
                         nothing, xlims, ylims, ann, scatter, fig, 5, xlsize,
                         legend_position, legendsize, titlesize, xscale, grid, label, xticks)
    if disp
        leg_labels = labels == ["", ""] ? string.(ylabels) : string.(labels)
        corner = _resolve_corner(legend_position, X,
                                 [_normalize01(Y1), _normalize01(Y2)])
        leg_ha, leg_va = _corner_align(corner)
        builder = function(layout)
            ax1 = Axis(layout[1, 1]; xlabel=string(xlabel),
                       ylabel=string(ylabels[1]), ylabelsize=ylsize,
                       xlabelsize=xlsize, xscale=_xscale_func(xscale),
                       ylabelcolor=:green, yticklabelcolor=:green,
                       title=title,
                       titlesize=titlesize,
                       titlefont=TITLE_FONT)
            if xscale == :log10
                ax1.xtickformat = xs -> [string(round(x, digits=1)) for x in xs]
            end
            if !isnothing(xticks)
                ax1.xticks = xticks
            end
            ax1.xgridvisible = grid
            ax1.ygridvisible = grid
            ax2 = Axis(layout[1, 1]; ylabel=string(ylabels[2]),
                       ylabelsize=ylsize, ylabelcolor=:red,
                       yticklabelcolor=:red, yaxisposition=:right,
                       backgroundcolor=RGBAf(0, 0, 0, 0))
            hidespines!(ax2)
            hidexdecorations!(ax2)
            linkxaxes!(ax1, ax2)
            l1 = lines!(ax1, X, Y1; linewidth=LINE_WIDTH, color=:green)
            l2 = lines!(ax2, X, Y2; linewidth=LINE_WIDTH, color=:red)
            if scatter
                scatter!(ax1, X, Y1; color=:red, markersize=8)
                scatter!(ax2, X, Y2; color=:red, markersize=8)
            end
            isnothing(xlims) || xlims!(ax1, xlims[1], xlims[2])
            if !isnothing(ylims) && length(ylims) == 2 &&
               ylims[1] isa Union{Tuple, AbstractVector}
                ylims!(ax1, ylims[1][1], ylims[1][2])
                ylims!(ax2, ylims[2][1], ylims[2][2])
            end
            Legend(layout[1, 1], [l1, l2], leg_labels;
                   tellwidth=false, tellheight=false, halign=leg_ha,
                   valign=leg_va, margin=(10, 10, 10, 10),
                   labelsize=legendsize)
            return (; axes=[ax1, ax2])
        end
        _show_interactive(builder; fig_name=fig, output_folder, new_screen)
    end
    return plotx_struct
end

function plot(X, Y1::AbstractVector{<:AbstractVector},
              Y2::AbstractVector{<:Number};
              xlabel="", ylabels=["", ""], title="", labels=["", ""],
              xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
              fig="", ysize=nothing, xsize=nothing, labelsize=16,
              legend_position=:auto, output_folder="output", disp=false,
              new_screen=true, legendsize=16, titlesize=18, xscale=:identity, grid=true, label="",
              xticks=nothing)
    if length(Y1) == 1
        return plot(X, Y1[1], Y2; xlabel, ylabels, title, labels, xlims,
                    ylims, ann, scatter, fig, ysize, xsize, labelsize,
                    legend_position, output_folder, disp, new_screen,
                    legendsize, titlesize, xscale, grid, label, xticks)
    end
    ylsize = isnothing(ysize) ? labelsize : ysize
    xlsize = isnothing(xsize) ? labelsize : xsize
    plotx_struct = PlotX(X, [Y1, Y2], labels, xlabel, ylabels, title, ylsize,
                         nothing, xlims, ylims, ann, scatter, fig, 5, xlsize,
                         legend_position, legendsize, titlesize, xscale, grid, label, xticks)
    if disp
        corner = _resolve_corner(legend_position, X,
                                 vcat(_normalize01.(Y1), [_normalize01(Y2)]))
        leg_ha, leg_va = _corner_align(corner)
        builder = function(layout)
            ax1 = Axis(layout[1, 1]; xlabel=string(xlabel),
                       ylabel=string(ylabels[1]), ylabelsize=ylsize,
                       xlabelsize=xlsize,
                       title=title,
                       titlesize=titlesize,
                       titlefont=TITLE_FONT)
            ax2 = Axis(layout[1, 1]; ylabel=string(ylabels[2]),
                       ylabelsize=ylsize, yaxisposition=:right,
                       backgroundcolor=RGBAf(0, 0, 0, 0))
            hidespines!(ax2)
            hidexdecorations!(ax2)
            linkxaxes!(ax1, ax2)
            colors = [:green, :grey, :red]
            lns = Any[]
            leg_labels = String[]
            for (i, Y) in pairs(Y1)
                c   = i <= length(colors) ? colors[i] : :black
                lbl = i <= length(labels) ? string(labels[i]) : ""
                ln  = lines!(ax1, X, Y; linewidth=LINE_WIDTH, color=c)
                push!(lns, ln)
                push!(leg_labels, lbl)
            end
            lbl2 = length(labels) >= length(Y1) + 1 ?
                   string(labels[end]) : ""
            ln2  = lines!(ax2, X, Y2; linewidth=LINE_WIDTH, color=:red)
            push!(lns, ln2)
            push!(leg_labels, lbl2)
            isnothing(xlims) || xlims!(ax1, xlims[1], xlims[2])
            Legend(layout[1, 1], lns, leg_labels;
                   tellwidth=false, tellheight=false, halign=leg_ha,
                   valign=leg_va, margin=(10, 10, 10, 10),
                   labelsize=legendsize)
            return (; axes=[ax1, ax2])
        end
        _show_interactive(builder; fig_name=fig, output_folder, new_screen)
    end
    return plotx_struct
end
