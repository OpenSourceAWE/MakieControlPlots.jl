mutable struct Plot2DState
    line_pts::Observable{Vector{Point2f}}
    scatter_pts::Observable{Vector{Point2f}}
    segment_pts::Vector{Observable{Vector{Point2f}}}
    label_text::Observable{String}
    label_pos::Observable{Point2f}
    xlim::Observable{NTuple{2, Float64}}
    ylim::Observable{NTuple{2, Float64}}
    front::Bool
    num_segs::Int
    screen::Any
end

const _PLOT2D_STATES = Dict{String, Plot2DState}()

function _make_plot2d_state(num_segs::Int, front::Bool)
    return Plot2DState(
        Observable(Point2f[]),
        Observable(Point2f[]),
        [Observable(Point2f[]) for _ in 1:num_segs],
        Observable(""),
        Observable(Point2f(0, 0)),
        Observable((0.0, 1.0)),
        Observable((0.0, 1.0)),
        front,
        num_segs,
        nothing,
    )
end

function plot2d(pos::AbstractVector, reltime::Real=0.0; zoom=true, front=false,
                segments::Integer=6, fig::String="", figsize=(6.4, 4.8),
                dpi=100, dz_zoom=1.5, dz=-5.0, dx=-16.0,
                xlim=nothing, ylim=nothing, xy=nothing)
    return _plot2d_impl(pos, nothing, reltime; zoom, front, segments, fig,
                        figsize, dpi, dz_zoom, dz, dx, xlim, ylim, xy)
end

function plot2d(pos::AbstractVector,
                seg::AbstractVector{<:AbstractVector{<:Integer}},
                reltime::Real=0.0; zoom=true, front=false,
                segments::Integer=6, fig::String="", figsize=(6.4, 4.8),
                dpi=100, dz_zoom=1.5, dz=1.0, dx=1.0,
                xlim=nothing, ylim=nothing, xy=nothing)
    return _plot2d_impl(pos, seg, reltime; zoom, front, segments, fig,
                        figsize, dpi, dz_zoom, dz, dx, xlim, ylim, xy)
end

function plot2d(pos_matrix::AbstractMatrix, reltime::Real=0.0;
                segments::Integer=6, kwargs...)
    pos_vectors = Vector{eltype(pos_matrix)}[]
    for particle in 1:segments+1
        push!(pos_vectors, pos_matrix[:, particle])
    end
    return plot2d(pos_vectors, reltime; segments, kwargs...)
end

function _plot2d_impl(pos, seg, reltime; zoom, front, segments, fig,
                      figsize, dpi, dz_zoom, dz, dx, xlim, ylim, xy)
    key = fig

    num_segs_needed = if !isnothing(seg)
        length(seg)
    elseif length(pos) > segments + 1
        5
    else
        0
    end

    state = get(_PLOT2D_STATES, key, nothing)
    must_rebuild = state === nothing ||
                   state.num_segs != num_segs_needed ||
                   state.front != front

    if must_rebuild
        if state !== nothing && state.screen !== nothing
            try
                close(state.screen)
            catch
            end
        end
        state = _make_plot2d_state(num_segs_needed, front)
        _PLOT2D_STATES[key] = state
    end

    x = Float64[front ? p[2] : p[1] for p in pos]
    z = Float64[p[3] for p in pos]
    x_max = maximum(x)
    x_min = minimum(x)
    z_max = maximum(z)

    pts = Point2f[Point2f(x[i], z[i]) for i in eachindex(x)]
    state.line_pts[] = pts
    state.scatter_pts[] = pts

    if !isnothing(seg)
        for (i, sg) in enumerate(seg)
            a, b = sg[1], sg[2]
            state.segment_pts[i][] =
                Point2f[Point2f(x[a], z[a]), Point2f(x[b], z[b])]
        end
    elseif length(pos) > segments + 1
        s = segments
        idx_pairs = ((s+1, s+4), (s+2, s+5), (s+3, s+5),
                     (s+2, s+4), (s+1, s+5))
        for (i, (a, b)) in enumerate(idx_pairs)
            state.segment_pts[i][] =
                Point2f[Point2f(x[a], z[a]), Point2f(x[b], z[b])]
        end
    end

    state.label_text[] = "t=$(round(reltime; digits=1)) s"

    new_xlim = if !isnothing(xlim)
        (Float64(xlim[1]), Float64(xlim[2]))
    elseif zoom
        if must_rebuild
            (Float64(x_max - 15.0), Float64(x_max + 5.0))
        else
            (Float64(x_min - 5.0), Float64(x_max + 5.0))
        end
    else
        (0.0, Float64(x_max + 5.0))
    end
    new_ylim = if !isnothing(ylim)
        (Float64(ylim[1]), Float64(ylim[2]))
    elseif zoom
        (Float64(z_max - 15.0), Float64(z_max + 5.0))
    else
        (0.0, Float64(z_max + 5.0))
    end
    state.xlim[] = new_xlim
    state.ylim[] = new_ylim

    label_xy = if zoom
        if isnothing(xy)
            (Float64(x_max), Float64(z_max + dz_zoom))
        else
            (Float64(xy[1]), Float64(xy[2]))
        end
    else
        if isnothing(xy)
            (Float64(x_max + dx), Float64(z_max + dz))
        else
            (Float64(xy[1]), Float64(xy[2]))
        end
    end
    if !zoom && !isnothing(seg)
        lx_lo, lx_hi = new_xlim
        ly_lo, ly_hi = new_ylim
        lx = max(min(label_xy[1], lx_hi - 1), lx_lo + 1)
        ly = max(min(label_xy[2], ly_hi - 1), ly_lo + 1)
        label_xy = (lx, ly)
    end
    state.label_pos[] = Point2f(label_xy[1], label_xy[2])

    if must_rebuild
        builder = function(layout)
            return _plot2d_build_axes!(layout, state, front)
        end
        size_px = (round(Int, figsize[1] * dpi),
                   round(Int, figsize[2] * dpi))
        (_, screen) = _show_interactive(builder; figsize=size_px,
                                        fig_name=key)
        state.screen = screen
    end

    return nothing
end

function _plot2d_build_axes!(layout, state::Plot2DState, front::Bool)
    xlabel = front ? "y [m]" : "x [m]"
    ax = Axis(layout[1, 1]; xlabel=xlabel, ylabel="z [m]")
    if front
        ax.xreversed = true
    end
    on(state.xlim) do lim
        xlims!(ax, lim[1], lim[2])
    end
    on(state.ylim) do lim
        ylims!(ax, lim[1], lim[2])
    end
    xlims!(ax, state.xlim[][1], state.xlim[][2])
    ylims!(ax, state.ylim[][1], state.ylim[][2])
    lines!(ax, state.line_pts; linewidth=1)
    scatter!(ax, state.scatter_pts; color=:red, markersize=8)
    for seg_pts in state.segment_pts
        lines!(ax, seg_pts; linewidth=1)
    end
    text!(ax, state.label_pos; text=state.label_text, fontsize=14,
          align=(:left, :bottom))
    return (; axes=[ax])
end
