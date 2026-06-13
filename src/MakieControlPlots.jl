module MakieControlPlots

using GLMakie
using CairoMakie
using Makie
using Makie: RGBAf
import JLD2
using StaticArraysCore
using LaTeXStrings

export plot, plotx, plotxy, plot2d, save, load, savefig, bode_plot

function bode_plot end

function __init__()
    try
        GLMakie.activate!()
    catch err
        @warn "could not activate GLMakie" err
    end
end

mutable struct PlotX
    X
    Y
    labels
    xlabel
    ylabels
    title::String
    ysize::Int
    yzoom
    xlims
    ylims
    ann
    scatter::Bool
    fig::String
    type::Int
    xsize::Int
    legend_position
    legendsize::Int
    titlesize::Int
end

save(filename::String, p::PlotX) = JLD2.save(filename, "plot", p)
load(filename::String) = JLD2.load(filename)["plot"]

include("controls.jl")
include("plot.jl")
include("plotx.jl")
include("plotxy.jl")
include("plot2d.jl")
include("precompile.jl")

function Base.display(p::PlotX; new_screen=true)
    if p.type == 1
        plot(p.X, p.Y; xlabel=p.xlabel, ylabel=p.ylabels, title=p.title,
             xlims=p.xlims, ylims=p.ylims, ann=p.ann, scatter=p.scatter,
             fig=p.fig, ysize=p.ysize, xsize=p.xsize, disp=true, new_screen,
             titlesize=p.titlesize)
    elseif p.type == 2
        plotx(p.X, p.Y...; xlabel=p.xlabel, ylabels=p.ylabels,
              title=p.title, labels=p.labels, xlims=p.xlims, ylims=p.ylims,
              ann=p.ann, scatter=p.scatter, fig=p.fig, ysize=p.ysize,
              xsize=p.xsize, legend_position=p.legend_position,
              yzoom=p.yzoom, legendsize=p.legendsize, disp=true, new_screen,
              titlesize=p.titlesize)
    elseif p.type == 3
        plotxy(p.X, p.Y; xlabel=p.xlabel, ylabel=p.ylabels, title=p.title,
               xlims=p.xlims, ylims=p.ylims, ann=p.ann, scatter=p.scatter,
               fig=p.fig, ysize=p.ysize, xsize=p.xsize, disp=true, new_screen,
               titlesize=p.titlesize)
    elseif p.type == 4
        plot(p.X, p.Y; xlabel=p.xlabel, ylabel=p.ylabels, title=p.title,
             labels=p.labels, xlims=p.xlims, ylims=p.ylims, ann=p.ann,
             scatter=p.scatter, fig=p.fig, ysize=p.ysize, xsize=p.xsize,
             legend_position=p.legend_position, legendsize=p.legendsize,
             disp=true, new_screen, titlesize=p.titlesize)
    elseif p.type == 5
        plot(p.X, p.Y[1], p.Y[2]; xlabel=p.xlabel, ylabels=p.ylabels,
             title=p.title, labels=p.labels, xlims=p.xlims, ylims=p.ylims,
             ann=p.ann, scatter=p.scatter, fig=p.fig, ysize=p.ysize,
             xsize=p.xsize, legend_position=p.legend_position,
             legendsize=p.legendsize, disp=true, new_screen,
             titlesize=p.titlesize)
    end
    return nothing
end

end
