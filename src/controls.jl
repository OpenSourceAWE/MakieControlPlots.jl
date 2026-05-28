const _LAST_BUILDER = Ref{Any}(nothing)

using Printf: @sprintf

function _interp_line_y(ax::Axis, x::Real)
    for p in ax.scene.plots
        p isa Makie.Lines || continue
        local raw
        try
            raw = p[1][]
        catch
            continue
        end
        (isempty(raw) || !(eltype(raw) <: Point)) && continue
        xs = Float64.(first.(raw))
        ys = Float64.(last.(raw))
        length(xs) < 2 && continue
        if !issorted(xs)
            ord = sortperm(xs)
            xs = xs[ord]
            ys = ys[ord]
        end
        (x < first(xs) || x > last(xs)) && continue
        i = searchsortedlast(xs, x)
        i == length(xs) && return ys[end]
        x0, y0 = xs[i], ys[i]
        x1, y1 = xs[i+1], ys[i+1]
        x1 == x0 && return y0
        t = (x - x0) / (x1 - x0)
        return y0 + t * (y1 - y0)
    end
    return nothing
end

function _set_interaction_active!(ax::Axis, name::Symbol, active::Bool)
    haskey(interactions(ax), name) || return nothing
    if active
        Makie.activate_interaction!(ax, name)
    else
        Makie.deactivate_interaction!(ax, name)
    end
    return nothing
end

function _extract_axes(artifacts)
    if artifacts isa NamedTuple && haskey(artifacts, :axes)
        return Axis[ax for ax in artifacts.axes if ax isa Axis]
    elseif artifacts isa Axis
        return Axis[artifacts]
    elseif artifacts isa AbstractVector
        return Axis[ax for ax in artifacts if ax isa Axis]
    else
        return Axis[]
    end
end

function _add_controls!(fig::Figure, axes_list::AbstractVector,
                        builder, fig_name::String)
    inactive_color = RGBAf(0.88, 0.88, 0.88, 1.0)
    active_color   = RGBAf(0.55, 0.78, 1.0, 1.0)
    grid = GridLayout(fig[2, 1]; tellwidth=false, tellheight=true)
    pan_btn   = Button(grid[1, 1]; label="⇆ Pan",   buttoncolor=inactive_color)
    zoom_btn  = Button(grid[1, 2]; label="⌕ Zoom",  buttoncolor=active_color)
    home_btn  = Button(grid[1, 3]; label="⌂ Home",  buttoncolor=inactive_color)
    png_btn   = Button(grid[1, 4]; label="↓ PNG",   buttoncolor=inactive_color)
    pdf_btn   = Button(grid[1, 5]; label="↓ PDF",   buttoncolor=inactive_color)
    value_btn = Button(grid[1, 6]; label="⌖ Value", buttoncolor=inactive_color)

    status = Observable("")
    cursor = Observable("x=0.0  y=0.0")
    Label(grid[2, 1:6], cursor; halign=:right, tellwidth=false,
          font=:regular)
    Box(grid[2, 1:6]; color=RGBAf(1, 1, 1, 1), strokevisible=false,
        visible=lift(s -> !isempty(s), status))
    Label(grid[2, 1:6], status; halign=:left, tellwidth=false)
    status_timer = Ref{Union{Nothing, Timer}}(nothing)
    flash_status! = function(msg)
        status[] = msg
        if status_timer[] !== nothing
            close(status_timer[])
        end
        status_timer[] = Timer(3.0) do _
            status[] = ""
        end
    end

    for ax in axes_list
        ax.panbutton[] = Makie.Mouse.left
    end
    mode = Ref(:zoom)
    apply_mode! = function()
        for ax in axes_list
            _set_interaction_active!(ax, :dragpan,       mode[] == :pan)
            _set_interaction_active!(ax, :rectanglezoom, mode[] == :zoom)
        end
        pan_btn.buttoncolor[]  = mode[] == :pan  ? active_color : inactive_color
        zoom_btn.buttoncolor[] = mode[] == :zoom ? active_color : inactive_color
    end
    apply_mode!()

    value_mode = Observable(false)
    hovered_axis = Observable{Union{Nothing, Axis}}(nothing)
    crosshair_pt = Observable(Point2f(0, 0))
    intersect_pt = Observable(Point2f(0, 0))
    intersect_text = Observable("")

    for ax in axes_list
        show_ch = lift(value_mode, hovered_axis) do v, h
            v && h === ax
        end
        cx = lift(p -> p[1], crosshair_pt)
        cy = lift(p -> p[2], crosshair_pt)
        vlines!(ax, cx; color=(:gray, 0.5), linestyle=:dot,
                linewidth=1, visible=show_ch, inspectable=false)
        hlines!(ax, cy; color=(:gray, 0.5), linestyle=:dot,
                linewidth=1, visible=show_ch, inspectable=false)
        scatter!(ax, intersect_pt; color=:red, markersize=6,
                 visible=show_ch, inspectable=false)
        text!(ax, intersect_pt; text=intersect_text, fontsize=11,
              align=(:left, :bottom), offset=(6, 6),
              visible=show_ch, inspectable=false)
    end

    on(value_btn.clicks) do _
        value_mode[] = !value_mode[]
        value_btn.buttoncolor[] =
            value_mode[] ? active_color : inactive_color
    end

    on(events(fig).mouseposition) do _
        for ax in axes_list
            Makie.is_mouseinside(ax.scene) || continue
            mpos = Makie.mouseposition(ax.scene)
            inv_tf = Makie.inverse_transform(ax.scene.transform_func[])
            x, y = Makie.apply_transform(inv_tf, mpos)
            cursor[] = @sprintf("x=%.4g  y=%.4g", x, y)
            crosshair_pt[] = Point2f(x, y)
            hovered_axis[] = ax
            if value_mode[]
                yi = _interp_line_y(ax, x)
                if !isnothing(yi)
                    intersect_pt[] = Point2f(x, yi)
                    intersect_text[] = @sprintf(" x=%.4g  y=%.4g", x, yi)
                else
                    intersect_text[] = ""
                end
            end
            return
        end
        cursor[] = "x=0.0  y=0.0"
        hovered_axis[] = nothing
    end

    on(pan_btn.clicks) do _
        mode[] = mode[] == :pan ? :none : :pan
        apply_mode!()
    end
    on(zoom_btn.clicks) do _
        mode[] = mode[] == :zoom ? :none : :zoom
        apply_mode!()
    end
    on(home_btn.clicks) do _
        for ax in axes_list
            reset_limits!(ax)
        end
    end
    base = isempty(fig_name) ? "plot" : fig_name
    on(png_btn.clicks) do _
        path = _export_figure(joinpath(pwd(), "$(base).png"), builder)
        flash_status!("saved $path")
    end
    on(pdf_btn.clicks) do _
        path = _export_figure(joinpath(pwd(), "$(base).pdf"), builder)
        flash_status!("saved $path")
    end
    return nothing
end

function _export_figure(filename::String, builder)
    fig = Figure()
    plot_grid = GridLayout(fig[1, 1])
    builder(plot_grid)
    CairoMakie.activate!()
    try
        Makie.save(filename, fig)
    finally
        GLMakie.activate!()
    end
    return filename
end

function _show_interactive(builder; figsize=(720, 580), fig_name::String="")
    fig = Figure(; size=figsize)
    plot_grid = GridLayout(fig[1, 1])
    artifacts = builder(plot_grid)
    axes_list = _extract_axes(artifacts)
    _add_controls!(fig, axes_list, builder, fig_name)
    _LAST_BUILDER[] = builder
    screen = display(fig)
    return (fig, screen)
end

function savefig(filename::String)
    if _LAST_BUILDER[] === nothing
        error("no plot to save; call plot/plotx/plotxy/plot2d with disp=true first")
    end
    path = _export_figure(filename, _LAST_BUILDER[])
    @info "wrote $path"
    return path
end
