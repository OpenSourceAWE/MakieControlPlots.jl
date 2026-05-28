using GLMakie
using CairoMakie

GLMakie.activate!()

mutable struct AnimState
    pos::Observable{Vector{Point2f}}
    label_text::Observable{String}
    label_pos::Observable{Point2f}
    ax::Union{Nothing, Axis}
end

AnimState() = AnimState(
    Observable(Point2f[Point2f(0, 0), Point2f(1, 0)]),
    Observable("t=0.0 s"),
    Observable(Point2f(1, 0.5)),
    nothing,
)

function reset_state!(state::AnimState)
    state.pos[]        = [Point2f(0, 0), Point2f(1, 0)]
    state.label_text[] = "t=0.0 s"
    state.label_pos[]  = Point2f(1, 0.5)
    return state
end

function update_state!(state::AnimState, pos::Vector{Point2f}, reltime::Real)
    if reltime == 0.0
        reset_state!(state)
    end
    state.pos[]        = pos
    state.label_text[] = "t=$(round(reltime; digits=1)) s"
    if !isempty(pos)
        state.label_pos[] = Point2f(pos[end][1], pos[end][2] + 0.5)
    end
    return state
end

function build_anim!(fig, state::AnimState)
    ax = Axis(fig[1, 1]; xlabel="x [m]", ylabel="z [m]", title="MWE animation")
    xlims!(ax, -2, 14)
    ylims!(ax, -2, 14)
    lines!(ax,   state.pos; color=:steelblue, linewidth=2)
    scatter!(ax, state.pos; color=:red,       markersize=12)
    text!(ax, state.label_pos; text=state.label_text, fontsize=14, align=(:left, :bottom))
    state.ax = ax
    return ax
end

function export_figure(filename::String, state::AnimState)
    fig = Figure()
    build_anim!(fig, state)
    CairoMakie.activate!()
    try
        Makie.save(filename, fig)
    finally
        GLMakie.activate!()
    end
    @info "wrote $filename"
end

function snapshot_interactions(ax)
    snap = Dict{Symbol, Any}()
    for (name, val) in interactions(ax)
        snap[name] = val isa Tuple ? val[end] : val
    end
    return snap
end

function set_interaction_active!(ax, snap::Dict{Symbol,Any}, name::Symbol, active::Bool)
    cur = interactions(ax)
    has = haskey(cur, name)
    if active && !has && haskey(snap, name)
        register_interaction!(ax, name, snap[name])
    elseif !active && has
        deregister_interaction!(ax, name)
    end
    return nothing
end

function add_controls!(fig, ax::Axis, state::AnimState)
    snap = snapshot_interactions(ax)
    grid = GridLayout(fig[2, 1]; tellwidth=false, tellheight=true)
    pan_btn  = Button(grid[1, 1]; label="Pan: on")
    zoom_btn = Button(grid[1, 2]; label="Zoom: on")
    home_btn = Button(grid[1, 3]; label="Home")
    png_btn  = Button(grid[1, 4]; label="Save PNG")
    pdf_btn  = Button(grid[1, 5]; label="Save PDF")

    pan_on  = Ref(true)
    zoom_on = Ref(true)

    on(pan_btn.clicks) do _
        pan_on[] = !pan_on[]
        set_interaction_active!(ax, snap, :dragpan, pan_on[])
        pan_btn.label = pan_on[] ? "Pan: on" : "Pan: off"
    end
    on(zoom_btn.clicks) do _
        zoom_on[] = !zoom_on[]
        set_interaction_active!(ax, snap, :rectanglezoom, zoom_on[])
        set_interaction_active!(ax, snap, :scrollzoom,    zoom_on[])
        zoom_btn.label = zoom_on[] ? "Zoom: on" : "Zoom: off"
    end
    on(home_btn.clicks) do _
        reset_limits!(ax)
    end
    on(png_btn.clicks) do _
        export_figure(joinpath(pwd(), "mwe.png"), state)
    end
    on(pdf_btn.clicks) do _
        export_figure(joinpath(pwd(), "mwe.pdf"), state)
    end
    return nothing
end

function interactive(state::AnimState)
    fig = Figure(; size=(720, 580))
    ax  = build_anim!(fig, state)
    add_controls!(fig, ax, state)
    display(fig)
    return fig
end

state = AnimState()
reset_state!(state)
interactive(state)

anim_task = @async begin
    try
        for k in 0:400
            t   = 0.05 * k
            tip = Point2f(1.0 + 0.05k, 0.05k)
            pos = Point2f[Point2f(0, 0), Point2f(1, 0), tip]
            update_state!(state, pos, t)
            sleep(0.05)
        end
        update_state!(state, Point2f[Point2f(0, 0), Point2f(1, 0)], 0.0)
    catch err
        @error "animation loop failed" exception=(err, catch_backtrace())
    end
end
