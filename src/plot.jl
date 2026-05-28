function plot(Y::AbstractVector{<:Number}; xlabel="", ylabel="", title="",
              fig="", ysize=14, disp=true)
    X = 1:length(Y)
    return plot(X, Y; xlabel, ylabel, title, fig, ysize, disp)
end

function plot(X, Y::AbstractVector{<:Number}; xlabel="", ylabel="", title="",
              xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
              fig="", ysize=14, disp=true)
    plotx_struct = PlotX(X, Y, nothing, xlabel, ylabel, title, ysize, nothing,
                         xlims, ylims, ann, scatter, fig, 1)
    if disp
        builder = function(layout)
            ax = Axis(layout[1, 1]; xlabel=string(xlabel),
                      ylabel=string(ylabel), ylabelsize=ysize)
            lines!(ax, X, Y)
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
            if title != ""
                Label(layout[0, 1], string(title); fontsize=14,
                      tellwidth=false)
            end
            return (; axes=[ax])
        end
        _show_interactive(builder; fig_name=fig)
    end
    return plotx_struct
end

function plot(X, Ys::AbstractVector{<:Union{AbstractVector, Tuple}};
              xlabel="", ylabel="", title="", labels=nothing, xlims=nothing,
              ylims=nothing, ann=nothing, scatter=false, fig="",
              ysize=14, disp=true)
    plotx_struct = PlotX(X, Ys, labels, xlabel, ylabel, title, ysize, nothing,
                         xlims, ylims, ann, scatter, fig, 4)
    if disp
        builder = function(layout)
            ax = Axis(layout[1, 1]; xlabel=string(xlabel),
                      ylabel=string(ylabel), ylabelsize=ysize)
            any_label = false
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
                            lines!(ax, X, Y; label=lbl); any_label = true
                        else
                            lines!(ax, X, Y)
                        end
                    else
                        errorbars!(ax, X, Y, Yerr; whiskerwidth=10)
                        if lbl != ""
                            lines!(ax, X, Y; label=lbl); any_label = true
                        else
                            lines!(ax, X, Y)
                        end
                    end
                    scatter && scatter!(ax, X, Y; color=:red, markersize=8)
                else
                    Y = YT
                    if lbl != ""
                        lines!(ax, X, Y; label=lbl); any_label = true
                    else
                        lines!(ax, X, Y)
                    end
                    scatter && scatter!(ax, X, Y; color=:red, markersize=8)
                end
            end
            isnothing(xlims) || xlims!(ax, xlims[1], xlims[2])
            isnothing(ylims) || ylims!(ax, ylims[1], ylims[2])
            if !isnothing(ann)
                text!(ax, ann[1], ann[2]; text=string(ann[3]), fontsize=14)
            end
            any_label && axislegend(ax)
            if title != ""
                Label(layout[0, 1], string(title); fontsize=14,
                      tellwidth=false)
            end
            return (; axes=[ax])
        end
        _show_interactive(builder; fig_name=fig)
    end
    return plotx_struct
end

function plot(X, Y1::AbstractVector{<:Number}, Y2::AbstractVector{<:Number};
              xlabel="", ylabels=["", ""], title="", labels=["", ""],
              xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
              fig="", ysize=14, disp=true)
    plotx_struct = PlotX(X, [Y1, Y2], labels, xlabel, ylabels, title, ysize,
                         nothing, xlims, ylims, ann, scatter, fig, 5)
    if disp
        leg_labels = labels == ["", ""] ? string.(ylabels) : string.(labels)
        builder = function(layout)
            ax1 = Axis(layout[1, 1]; xlabel=string(xlabel),
                       ylabel=string(ylabels[1]), ylabelsize=ysize,
                       ylabelcolor=:green, yticklabelcolor=:green)
            ax2 = Axis(layout[1, 1]; ylabel=string(ylabels[2]),
                       ylabelsize=ysize, ylabelcolor=:red,
                       yticklabelcolor=:red, yaxisposition=:right,
                       backgroundcolor=RGBAf(0, 0, 0, 0))
            hidespines!(ax2)
            hidexdecorations!(ax2)
            linkxaxes!(ax1, ax2)
            l1 = lines!(ax1, X, Y1; color=:green)
            l2 = lines!(ax2, X, Y2; color=:red)
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
                   tellwidth=false, tellheight=false, halign=:left,
                   valign=:top, margin=(10, 10, 10, 10))
            if title != ""
                Label(layout[0, 1], string(title); fontsize=14,
                      tellwidth=false)
            end
            return (; axes=[ax1, ax2])
        end
        _show_interactive(builder; fig_name=fig)
    end
    return plotx_struct
end

function plot(X, Y1::AbstractVector{<:AbstractVector},
              Y2::AbstractVector{<:Number};
              xlabel="", ylabels=["", ""], title="", labels=["", ""],
              xlims=nothing, ylims=nothing, ann=nothing, scatter=false,
              fig="", ysize=14, disp=true)
    if length(Y1) == 1
        return plot(X, Y1[1], Y2; xlabel, ylabels, title, labels, xlims,
                    ylims, ann, scatter, fig, ysize, disp)
    end
    plotx_struct = PlotX(X, [Y1, Y2], labels, xlabel, ylabels, title, ysize,
                         nothing, xlims, ylims, ann, scatter, fig, 5)
    if disp
        builder = function(layout)
            ax1 = Axis(layout[1, 1]; xlabel=string(xlabel),
                       ylabel=string(ylabels[1]), ylabelsize=ysize)
            ax2 = Axis(layout[1, 1]; ylabel=string(ylabels[2]),
                       ylabelsize=ysize, yaxisposition=:right,
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
                ln  = lines!(ax1, X, Y; color=c)
                push!(lns, ln)
                push!(leg_labels, lbl)
            end
            lbl2 = length(labels) >= length(Y1) + 1 ?
                   string(labels[end]) : ""
            ln2  = lines!(ax2, X, Y2; color=:red)
            push!(lns, ln2)
            push!(leg_labels, lbl2)
            isnothing(xlims) || xlims!(ax1, xlims[1], xlims[2])
            Legend(layout[1, 1], lns, leg_labels;
                   tellwidth=false, tellheight=false, halign=:left,
                   valign=:top, margin=(10, 10, 10, 10))
            if title != ""
                Label(layout[0, 1], string(title); fontsize=14,
                      tellwidth=false)
            end
            return (; axes=[ax1, ax2])
        end
        _show_interactive(builder; fig_name=fig)
    end
    return plotx_struct
end
