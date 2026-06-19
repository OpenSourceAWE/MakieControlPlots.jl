module MakieControlPlots

using GLMakie
using CairoMakie
using Makie
using Makie: RGBAf
import JLD2
using StaticArraysCore
using LaTeXStrings
import Base: close

export plot, plotx, plotxy, plot2d, save, load, savefig, bode_plot, close,
       migrate_legacy_plotx_file

TITLE_FONT::String = "CMU Serif"
LINE_WIDTH::Float64 = 2

function bode_plot end

function _xscale_func(xscale::Symbol)
    if xscale == :log10
        return log10
    elseif xscale == :log2
        return log2
    elseif xscale == :ln
        return log
    else
        return identity
    end
end

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
    xscale::Symbol
    grid::Bool
    label::String
    xticks
end

# Serialization format version — bump when adding/removing fields
const _PLOTX_SERIAL_VERSION = 2

# ── Migration-safe save/load ────────────────────────────────────────────────
# Instead of raw struct serialization we use a versioned Dict.
# This ensures old .jld2 files can still be read by filling defaults for
# missing keys.
#
# Legacy files (v0.1.3 and earlier) saved the struct directly. JLD2 cannot
# reconstruct the new struct from old data, so we use JLD2.Upgrade with a
# custom rconvert to fill sensible defaults for newly added fields.

function save(filename::String, p::PlotX)
    data = Dict{Symbol, Any}(
        :__version__ => _PLOTX_SERIAL_VERSION,
        :X           => p.X,
        :Y           => p.Y,
        :labels      => p.labels,
        :xlabel      => p.xlabel,
        :ylabels     => p.ylabels,
        :title       => p.title,
        :ysize       => p.ysize,
        :yzoom       => p.yzoom,
        :xlims       => p.xlims,
        :ylims       => p.ylims,
        :ann         => p.ann,
        :scatter     => p.scatter,
        :fig         => p.fig,
        :type        => p.type,
        :xsize       => p.xsize,
        :legend_position => p.legend_position,
        :legendsize  => p.legendsize,
        :titlesize   => p.titlesize,
        :xscale      => p.xscale,
        :grid        => p.grid,
        :label       => p.label,
        :xticks      => p.xticks,
    )
    JLD2.save(filename, "plot", data)
end

"""
    JLD2.rconvert(::Type{PlotX}, nt::NamedTuple)

Used by `JLD2.Upgrade` to reconstruct a `PlotX` from legacy serialized data
when loading files saved by v0.1.3 or earlier.
"""
function JLD2.rconvert(::Type{PlotX}, nt::NamedTuple)
    return PlotX(
        get(nt, :X,                   nothing),
        get(nt, :Y,                   nothing),
        get(nt, :labels,              nothing),
        get(nt, :xlabel,              nothing),
        get(nt, :ylabels,             nothing),
        get(nt, :title,               ""),
        get(nt, :ysize,               16),
        get(nt, :yzoom,               nothing),
        get(nt, :xlims,               nothing),
        get(nt, :ylims,               nothing),
        get(nt, :ann,                 nothing),
        get(nt, :scatter,             false),
        get(nt, :fig,                 ""),
        get(nt, :type,                1),
        get(nt, :xsize,               16),
        get(nt, :legend_position,     :auto),
        get(nt, :legendsize,          16),
        get(nt, :titlesize,           18),
        get(nt, :xscale,              :identity),
        get(nt, :grid,                true),
        get(nt, :label,               ""),
        get(nt, :xticks,              nothing),
    )
end

function load(filename::String)
    raw = JLD2.load(filename; typemap=Dict(
        "MakieControlPlots.PlotX" => JLD2.Upgrade(PlotX),
    ))["plot"]
    raw isa PlotX && return raw
    return _reconstruct_plotx(raw)
end

function _reconstruct_plotx(d::Dict)
    return PlotX(
        get(d, :X,                   nothing),
        get(d, :Y,                   nothing),
        get(d, :labels,              nothing),
        get(d, :xlabel,              nothing),
        get(d, :ylabels,             nothing),
        get(d, :title,               ""),
        get(d, :ysize,               16),
        get(d, :yzoom,               nothing),
        get(d, :xlims,               nothing),
        get(d, :ylims,               nothing),
        get(d, :ann,                 nothing),
        get(d, :scatter,             false),
        get(d, :fig,                 ""),
        get(d, :type,                1),
        get(d, :xsize,               16),
        get(d, :legend_position,     :auto),
        get(d, :legendsize,          16),
        get(d, :titlesize,           18),
        get(d, :xscale,              :identity),
        get(d, :grid,                true),
        get(d, :label,               ""),
        get(d, :xticks,              nothing),
    )
end

"""
    migrate_legacy_plotx_file(input_path; output_path=nothing)

Read a .jld2 file saved by an older version of MakieControlPlots (v0.1.3 or
earlier) and rewrite it in the current versioned Dict format.

If `output_path` is `nothing` (default) the file is updated in-place.
Returns `true` on success, `false` if the file is already up-to-date.
"""
function migrate_legacy_plotx_file(input_path::String; output_path=nothing)
    raw = JLD2.load(input_path)["plot"]
    raw isa Dict && return false   # already migrated
    # Load via Upgrade and re-save in Dict format
    dest = something(output_path, input_path)
    p = load(input_path)
    save(dest, p)
    return true
end

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
             titlesize=p.titlesize, legendsize=p.legendsize,
             xscale=p.xscale, grid=p.grid, label=p.label, xticks=p.xticks)
    elseif p.type == 2
        plotx(p.X, p.Y...; xlabel=p.xlabel, ylabels=p.ylabels,
              title=p.title, labels=p.labels, xlims=p.xlims, ylims=p.ylims,
              ann=p.ann, scatter=p.scatter, fig=p.fig, ysize=p.ysize,
              xsize=p.xsize, legend_position=p.legend_position,
              yzoom=p.yzoom, legendsize=p.legendsize, disp=true, new_screen,
              titlesize=p.titlesize, xscale=p.xscale, grid=p.grid)
    elseif p.type == 3
        plotxy(p.X, p.Y; xlabel=p.xlabel, ylabel=p.ylabels, title=p.title,
               xlims=p.xlims, ylims=p.ylims, ann=p.ann, scatter=p.scatter,
               fig=p.fig, ysize=p.ysize, xsize=p.xsize, disp=true, new_screen,
               titlesize=p.titlesize, legendsize=p.legendsize,
               xscale=p.xscale, grid=p.grid)
    elseif p.type == 4
        plot(p.X, p.Y; xlabel=p.xlabel, ylabel=p.ylabels, title=p.title,
             labels=p.labels, xlims=p.xlims, ylims=p.ylims, ann=p.ann,
             scatter=p.scatter, fig=p.fig, ysize=p.ysize, xsize=p.xsize,
             legend_position=p.legend_position, legendsize=p.legendsize,
             disp=true, new_screen, titlesize=p.titlesize,
             xscale=p.xscale, grid=p.grid, label=p.label, xticks=p.xticks)
    elseif p.type == 5
        plot(p.X, p.Y[1], p.Y[2]; xlabel=p.xlabel, ylabels=p.ylabels,
             title=p.title, labels=p.labels, xlims=p.xlims, ylims=p.ylims,
             ann=p.ann, scatter=p.scatter, fig=p.fig, ysize=p.ysize,
             xsize=p.xsize, legend_position=p.legend_position,
             legendsize=p.legendsize, disp=true, new_screen,
             titlesize=p.titlesize, xscale=p.xscale, grid=p.grid,
             label=p.label, xticks=p.xticks)
    end
    return nothing
end

end
