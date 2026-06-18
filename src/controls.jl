const _LAST_BUILDER = Ref{Any}(nothing)
const _LAST_FIGSIZE = Ref{Any}(nothing)
const _LAST_AXES = Ref{Any}(nothing)
const _SCREENS = Dict{String, Any}()
const _CONTROLS_HEIGHT = 40
const _DEFAULT_PLOTSIZE = (640, 480)

using Printf: @sprintf

function _interp_line_y(p, x::Real)
    local raw
    try
        raw = p[1][]
    catch
        return nothing
    end
    (isempty(raw) || !(eltype(raw) <: Point)) && return nothing
    xs = Float64.(first.(raw))
    ys = Float64.(last.(raw))
    length(xs) < 2 && return nothing
    if !issorted(xs)
        ord = sortperm(xs)
        xs = xs[ord]
        ys = ys[ord]
    end
    (x < first(xs) || x > last(xs)) && return nothing
    i = searchsortedlast(xs, x)
    i == length(xs) && return ys[end]
    x0, y0 = xs[i], ys[i]
    x1, y1 = xs[i+1], ys[i+1]
    x1 == x0 && return y0
    t = (x - x0) / (x1 - x0)
    return y0 + t * (y1 - y0)
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

function _copy_clipboard(str::String)
    try
        open(`wl-copy`, "w") do io
            print(io, str)
        end
    catch err
        @warn "could not copy to clipboard via wl-copy" err
    end
    return nothing
end

function _ensure_folder(folder)
    f = isempty(folder) ? "." : folder
    isdir(f) || mkpath(f)
    return f
end

function _path_string(output_folder, base, ext)
    folder = isempty(output_folder) ? "." : output_folder
    name = replace(base, " " => "_")
    return joinpath(folder, "$(name).$(ext)")
end

function _output_path(output_folder, base, ext)
    _ensure_folder(output_folder)
    return _path_string(output_folder, base, ext)
end

function _legend_corner(xvals, yvecs)
    isempty(yvecs) && return :rt
    xs = Float64.(collect(xvals))
    isempty(xs) && return :rt
    xmin, xmax = extrema(xs)
    ys_all = reduce(vcat, (Float64.(y) for y in yvecs))
    isempty(ys_all) && return :rt
    ymin, ymax = extrema(ys_all)
    nx(x) = xmax == xmin ? 0.5 : (x - xmin) / (xmax - xmin)
    ny(y) = ymax == ymin ? 0.5 : (y - ymin) / (ymax - ymin)
    corners = ((:lb, 0.0, 0.0), (:rb, 1.0, 0.0),
               (:lt, 0.0, 1.0), (:rt, 1.0, 1.0))
    best_corner = :rt
    best_dist = -1.0
    for (name, cx, cy) in corners
        nearest = Inf
        for y in yvecs
            for (xi, yi) in zip(xs, Float64.(y))
                d = (nx(xi) - cx)^2 + (ny(yi) - cy)^2
                d < nearest && (nearest = d)
            end
        end
        if nearest > best_dist
            best_dist = nearest
            best_corner = name
        end
    end
    return best_corner
end

function _resolve_corner(legend_position, xvals, yvecs)
    return legend_position === :auto ? _legend_corner(xvals, yvecs) :
           legend_position
end

function _normalize01(y)
    yf = Float64.(y)
    lo, hi = extrema(yf)
    hi == lo && return fill(0.5, length(yf))
    return (yf .- lo) ./ (hi - lo)
end

function _corner_align(corner::Symbol)
    ha = corner in (:lb, :lt) ? :left : :right
    va = corner in (:lb, :rb) ? :bottom : :top
    return (ha, va)
end

function _mouse_data(ax::Axis)
    mpos = Makie.mouseposition(ax.scene)
    inv_tf = Makie.inverse_transform(Makie.transform_func(ax.scene))
    return Makie.apply_transform(inv_tf, mpos)
end

function _emptiest_side(px, py, lines, lims)
    ox, oy = lims.origin[1], lims.origin[2]
    wx, wy = lims.widths[1], lims.widths[2]
    (wx == 0 || wy == 0) && return ((8.0, 8.0), (:left, :bottom))
    nxp = (px - ox) / wx
    nyp = (py - oy) / wy
    radius = 0.18
    counts = Dict(:rt => 0, :lt => 0, :rb => 0, :lb => 0)
    for ln in lines
        local raw
        try
            raw = ln[1][]
        catch
            continue
        end
        for pt in raw
            dx = (pt[1] - ox) / wx - nxp
            dy = (pt[2] - oy) / wy - nyp
            (abs(dx) > radius || abs(dy) > radius) && continue
            (dx == 0 && dy == 0) && continue
            counts[dx >= 0 ? (dy >= 0 ? :rt : :rb) :
                   (dy >= 0 ? :lt : :lb)] += 1
        end
    end
    side = findmin(counts)[2]
    sx = side in (:rt, :rb) ? 1.0 : -1.0
    sy = side in (:rt, :lt) ? 1.0 : -1.0
    return ((sx * 8.0, sy * 8.0),
            (sx > 0 ? :left : :right, sy > 0 ? :bottom : :top))
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
                        builder, fig_name::String; output_folder="output",
                        fig_width=640, figsize=_DEFAULT_PLOTSIZE)
    inactive_color = RGBAf(0.88, 0.88, 0.88, 1.0)
    active_color   = RGBAf(0.55, 0.78, 1.0, 1.0)
    btn_fontsize = 12
    info_fontsize = 13
    btn_labels = ["⌂ Home", "⌕ Zoom", "⇆ Pan", "↓ PNG", "↓ PDF", "⌖ Value"]
    grid = GridLayout(fig[2, 1]; tellwidth=false, tellheight=true)
    btns = GridLayout(grid[1, 1]; tellwidth=true)
    sum_len = sum(length, btn_labels)
    btn_overhead = 6 * 12 + 5 * 4 + 16
    fit_btn_fs = function(w)
        avail = (w <= 1 ? fig_width : w) - 8
        raw = (avail - btn_overhead) / (sum_len * 0.6)
        return clamp(2.0 * floor(raw / 2), 6.0, Float64(btn_fontsize))
    end
    btn_fs = lift(area -> fit_btn_fs(Makie.widths(area)[1]),
                  events(fig).window_area)
    mkbtn = function(col, lbl, is_active)
        return Button(btns[1, col]; label=lbl, fontsize=btn_fs,
                      height=26, padding=(6, 6, 3, 3),
                      buttoncolor=is_active ? active_color : inactive_color)
    end
    home_btn  = mkbtn(1, btn_labels[1], false)
    zoom_btn  = mkbtn(2, btn_labels[2], true)
    pan_btn   = mkbtn(3, btn_labels[3], false)
    png_btn   = mkbtn(4, btn_labels[4], false)
    pdf_btn   = mkbtn(5, btn_labels[5], false)
    value_btn = mkbtn(6, btn_labels[6], false)
    colgap!(btns, 4)

    base = isempty(fig_name) ? "plot" : fig_name
    status = Observable("")
    cursor = Observable("x=0.0  y=0.0")
    info = lift(status, cursor) do s, c
        isempty(s) ? c : s
    end
    text_px(str, sz) = length(str) * 0.6 * sz
    btns_px = sum(text_px(l, btn_fontsize) + 12 for l in btn_labels) +
              5 * 4 + 16
    save_sample = "saved " * _path_string(output_folder, base, "pdf")
    cursor_sample = "x=-1.2346e+05  y=-1.2346e+05"
    widest = length(save_sample) >= length(cursor_sample) ? save_sample :
             cursor_sample
    need_px = btns_px + 8 + text_px(widest, info_fontsize) + 12
    fits_right = lift(events(fig).window_area) do area
        w = Makie.widths(area)[1]
        need_px <= (w <= 1 ? fig_width : w)
    end
    Label(grid[1, 2], info; halign=:right, tellwidth=false,
          fontsize=info_fontsize, visible=fits_right)
    Label(grid[2, 1], info; halign=:left, tellwidth=false,
          fontsize=info_fontsize, visible=lift(!, fits_right))
    update_info_layout = function(fr)
        rowsize!(grid, 2, fr ? Makie.Fixed(0.0) : Makie.Auto())
        rowgap!(grid, 1, fr ? 0.0 : 4.0)
    end
    on(update_info_layout, fits_right)
    update_info_layout(fits_right[])
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
            _set_interaction_active!(ax, :dragpan, mode[] == :pan)
            _set_interaction_active!(ax, :rectanglezoom, false)
        end
        pan_btn.buttoncolor[]  = mode[] == :pan  ? active_color : inactive_color
        zoom_btn.buttoncolor[] = mode[] == :zoom ? active_color : inactive_color
    end
    apply_mode!()

    zoom_start = Dict{Axis, Point2f}()
    zooming = Ref(false)
    press_px = Ref(Point2f(0, 0))
    rubber = Observable(Rect2f(0, 0, 0, 0))
    rubber_vis = Observable(false)
    rubber_plot = poly!(fig.scene, rubber; space=:pixel,
                        color=RGBAf(0.3, 0.5, 1.0, 0.12),
                        strokecolor=RGBAf(0.2, 0.4, 0.9, 0.8),
                        strokewidth=1, visible=rubber_vis, inspectable=false)
    translate!(rubber_plot, 0, 0, 1000)

    value_mode = Observable(false)
    crosshair_x = Observable(0.0)
    crosshair_pt = Observable(Point2f(0, 0))
    hovered = Dict{Axis, Observable{Bool}}()
    cross_y = Dict{Axis, Observable{Float64}}()
    line_markers = Dict{Axis, Vector{NamedTuple}}()
    axis_lines = Dict{Axis, Vector{Any}}()

    for ax in axes_list
        hovered[ax] = Observable(false)
        cross_y[ax] = Observable(0.0)
        show_ch = lift((v, h) -> v && h, value_mode, hovered[ax])
        vlines!(ax, crosshair_x; color=(:gray, 0.5), linestyle=:dot,
                linewidth=1, visible=show_ch, inspectable=false)
        hlines!(ax, cross_y[ax]; color=(:gray, 0.5), linestyle=:dot,
                linewidth=1, visible=show_ch, inspectable=false)

        lines_here = Any[p for p in ax.scene.plots if p isa Makie.Lines]
        axis_lines[ax] = lines_here
        markers = NamedTuple[]
        for line in lines_here
            pt_obs = Observable(Point2f(NaN, NaN))
            lbl_obs = Observable("")
            off_obs = Observable((8.0, 8.0))
            align_obs = Observable((:left, :bottom))
            scatter!(ax, pt_obs; color=:red, markersize=6,
                     visible=show_ch, inspectable=false)
            text!(ax, pt_obs; text=lbl_obs, fontsize=11, offset=off_obs,
                  align=align_obs, color=:black, visible=show_ch,
                  inspectable=false)
            push!(markers, (line=line, pt=pt_obs, lbl=lbl_obs, off=off_obs,
                            align=align_obs))
        end
        line_markers[ax] = markers
    end

    on(value_btn.clicks) do _
        value_mode[] = !value_mode[]
        value_btn.buttoncolor[] =
            value_mode[] ? active_color : inactive_color
    end

    on(events(fig).mouseposition) do _
        if zooming[]
            cur = events(fig).mouseposition[]
            s = press_px[]
            rubber[] = Rect2f(min(s[1], cur[1]), min(s[2], cur[2]),
                              abs(cur[1] - s[1]), abs(cur[2] - s[2]))
        end
        primary = false
        for ax in axes_list
            inside = Makie.is_mouseinside(ax.scene)
            hovered[ax][] = inside
            inside || continue
            mpos = Makie.mouseposition(ax.scene)
            inv_tf = Makie.inverse_transform(Makie.transform_func(ax.scene))
            x, y = Makie.apply_transform(inv_tf, mpos)
            cross_y[ax][] = y
            if !primary
                primary = true
                crosshair_x[] = x
                crosshair_pt[] = Point2f(x, y)
                cursor[] = @sprintf("x=%.4g  y=%.4g", x, y)
            end
            value_mode[] || continue
            lims = ax.finallimits[]
            for m in line_markers[ax]
                yi = _interp_line_y(m.line, x)
                if isnothing(yi)
                    m.pt[] = Point2f(NaN, NaN)
                    m.lbl[] = ""
                else
                    m.pt[] = Point2f(x, yi)
                    m.lbl[] = @sprintf("x=%.4g  y=%.4g", x, yi)
                    off, align = _emptiest_side(x, yi, axis_lines[ax], lims)
                    m.off[] = off
                    m.align[] = align
                end
            end
        end
        primary || (cursor[] = "x=0.0  y=0.0")
    end

    on(events(fig).mousebutton) do event
        event.button == Makie.Mouse.left || return
        if event.action == Makie.Mouse.press
            press_px[] = events(fig).mouseposition[]
            if mode[] == :zoom
                empty!(zoom_start)
                for ax in axes_list
                    Makie.is_mouseinside(ax.scene) || continue
                    zoom_start[ax] = _mouse_data(ax)
                end
                if !isempty(zoom_start)
                    rubber[] = Rect2f(press_px[][1], press_px[][2], 0, 0)
                    rubber_vis[] = true
                    zooming[] = true
                end
            end
            return
        end
        cur_px = events(fig).mouseposition[]
        moved = hypot(cur_px[1] - press_px[][1], cur_px[2] - press_px[][2])
        if zooming[]
            zooming[] = false
            rubber_vis[] = false
            if moved >= 5
                for (ax, sd) in zoom_start
                    ed = _mouse_data(ax)
                    lo1, hi1 = minmax(sd[1], ed[1])
                    lo2, hi2 = minmax(sd[2], ed[2])
                    (hi1 > lo1 && hi2 > lo2) &&
                        (ax.targetlimits[] = Makie.BBox(lo1, hi1, lo2, hi2))
                end
            end
            empty!(zoom_start)
        end
        (value_mode[] && moved < 5) || return
        any(h -> h[], values(hovered)) || return
        pts = Point2f[]
        for ax in axes_list
            hovered[ax][] || continue
            for m in line_markers[ax]
                p = m.pt[]
                isnan(p[1]) || push!(pts, p)
            end
        end
        if isempty(pts)
            p = crosshair_pt[]
            pts = Point2f[p]
        end
        coords = "[" *
            join((@sprintf("(%.6g, %.6g)", p[1], p[2]) for p in pts), ", ") *
            "]"
        _copy_clipboard(coords)
        flash_status!("copied $coords")
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
    on(png_btn.clicks) do _
        path = _export_figure(_output_path(output_folder, base, "png"), builder,
                              axes_list; figsize)
        flash_status!("saved $path")
    end
    on(pdf_btn.clicks) do _
        path = _export_figure(_output_path(output_folder, base, "pdf"), builder,
                              axes_list; figsize)
        flash_status!("saved $path")
    end
    return nothing
end

"""
    _copy_limits!(target_axes, source_axes)

Copy the current view (zoom/pan) from each source axis onto the matching
target axis, so exports reflect what is shown on screen.
"""
function _copy_limits!(target_axes, source_axes)
    source_axes isa AbstractVector || return nothing
    length(target_axes) == length(source_axes) || return nothing
    for (target, source) in zip(target_axes, source_axes)
        Makie.limits!(target, source.finallimits[])
    end
    return nothing
end

function _export_figure(filename::String, builder, source_axes=nothing;
                        figsize=_DEFAULT_PLOTSIZE)
    fig = Figure(; size=figsize)
    plot_grid = GridLayout(fig[1, 1])
    artifacts = builder(plot_grid)
    if source_axes !== nothing
        _copy_limits!(_extract_axes(artifacts), source_axes)
    end
    CairoMakie.activate!()
    try
        if endswith(lowercase(filename), ".png")
            Makie.save(filename, fig; px_per_unit=1)
        else
            Makie.save(filename, fig)
        end
    finally
        GLMakie.activate!()
    end
    return filename
end

function _prime_focus!(fig::Figure, screen)
    screen isa GLMakie.Screen || return nothing
    events(fig).hasfocus[] = true
    return nothing
end

"""
    close(fig_name::String)

Close the figure with the given name. If `fig_name` is `"all"` or `"ALL"`,
close all open figures.
"""
function close(fig_name::String)
    if fig_name in ("all", "ALL")
        for (name, screen) in _SCREENS
            try
                GLMakie.close(screen)
            catch
            end
        end
        empty!(_SCREENS)
        return nothing
    end
    screen = get(_SCREENS, fig_name, nothing)
    if screen === nothing
        @warn "Figure \"$fig_name\" not found. Open figures: $(collect(keys(_SCREENS)))"
        return nothing
    end
    try
        GLMakie.close(screen)
    catch
    end
    delete!(_SCREENS, fig_name)
    return nothing
end

function _display_figure(fig::Figure, fig_name::String, new_screen::Bool)
    if !(new_screen && Makie.current_backend() === GLMakie)
        return display(fig)
    end
    title = isempty(fig_name) ? "Makie" : fig_name
    existing = get(_SCREENS, fig_name, nothing)
    if existing isa GLMakie.Screen && isopen(existing)
        GLMakie.set_title!(existing, title)
        display(existing, fig)
        return existing
    end
    screen = GLMakie.Screen(; title)
    for k in collect(keys(_SCREENS))
        _SCREENS[k] === screen && delete!(_SCREENS, k)
    end
    _SCREENS[fig_name] = screen
    display(screen, fig)
    return screen
end

function _show_interactive(builder; figsize=_DEFAULT_PLOTSIZE,
                           fig_name::String="", output_folder="output",
                           new_screen=true)
    window_size = (figsize[1], figsize[2] + _CONTROLS_HEIGHT)
    fig = Figure(; size=window_size)
    plot_grid = GridLayout(fig[1, 1])
    artifacts = builder(plot_grid)
    axes_list = _extract_axes(artifacts)
    _add_controls!(fig, axes_list, builder, fig_name; output_folder,
                   fig_width=window_size[1], figsize)
    _LAST_BUILDER[] = builder
    _LAST_FIGSIZE[] = figsize
    _LAST_AXES[] = axes_list
    screen = _display_figure(fig, fig_name, new_screen)
    _prime_focus!(fig, screen)
    return (fig, screen)
end

function savefig(filename::String; output_folder="output")
    if _LAST_BUILDER[] === nothing
        error("no plot to save; call plot/plotx/plotxy/plot2d with disp=true first")
    end
    dir = dirname(filename)
    name = replace(basename(filename), " " => "_")
    target = isempty(dir) ? joinpath(_ensure_folder(output_folder), name) :
             joinpath(dir, name)
    figsize = something(_LAST_FIGSIZE[], _DEFAULT_PLOTSIZE)
    path = _export_figure(target, _LAST_BUILDER[], _LAST_AXES[]; figsize)
    @info "wrote $path"
    return path
end
