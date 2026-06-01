const _LAST_BUILDER = Ref{Any}(nothing)

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

function _corner_relpos(corner::Symbol)
    x = corner in (:lb, :lt) ? 0.02 : 0.98
    y = corner in (:lb, :rb) ? 0.02 : 0.98
    return (Point2f(x, y), _corner_align(corner))
end

function _axis_line_data(lines)
    xs = Float64[]
    yvecs = Vector{Float64}[]
    for ln in lines
        local raw
        try
            raw = ln[1][]
        catch
            continue
        end
        (isempty(raw) || !(eltype(raw) <: Point)) && continue
        isempty(xs) && (xs = Float64.(first.(raw)))
        push!(yvecs, Float64.(last.(raw)))
    end
    return xs, yvecs
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
                        fig_width=720)
    inactive_color = RGBAf(0.88, 0.88, 0.88, 1.0)
    active_color   = RGBAf(0.55, 0.78, 1.0, 1.0)
    btn_fontsize = 12
    info_fontsize = 13
    btn_labels = ["⇆ Pan", "⌕ Zoom", "⌂ Home", "↓ PNG", "↓ PDF", "⌖ Value"]
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
    pan_btn   = mkbtn(1, btn_labels[1], false)
    zoom_btn  = mkbtn(2, btn_labels[2], true)
    home_btn  = mkbtn(3, btn_labels[3], false)
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
    line_markers = Dict{Axis, Vector{Tuple{Any, Observable{Point2f}}}}()
    axis_readout = Dict{Axis, Observable{String}}()

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

        lines_here = Any[p for p in ax.scene.plots if p isa Makie.Lines]
        markers = Tuple{Any, Observable{Point2f}}[]
        for line in lines_here
            pt_obs = Observable(Point2f(NaN, NaN))
            scatter!(ax, pt_obs; color=:red, markersize=6,
                     visible=show_ch, inspectable=false)
            push!(markers, (line, pt_obs))
        end
        line_markers[ax] = markers

        xs, yvecs = _axis_line_data(lines_here)
        corner = isempty(yvecs) ? :rt : _legend_corner(xs, yvecs)
        relpos, talign = _corner_relpos(corner)
        readout = Observable("")
        axis_readout[ax] = readout
        text!(ax, relpos; text=readout, space=:relative, align=talign,
              fontsize=12, color=:black, visible=show_ch, inspectable=false)
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
            inv_tf = Makie.inverse_transform(Makie.transform_func(ax.scene))
            x, y = Makie.apply_transform(inv_tf, mpos)
            cursor[] = @sprintf("x=%.4g  y=%.4g", x, y)
            crosshair_pt[] = Point2f(x, y)
            hovered_axis[] = ax
            if value_mode[]
                parts = String[@sprintf("x=%.4g", x)]
                for (line, pt_obs) in line_markers[ax]
                    yi = _interp_line_y(line, x)
                    if isnothing(yi)
                        pt_obs[] = Point2f(NaN, NaN)
                    else
                        pt_obs[] = Point2f(x, yi)
                        push!(parts, @sprintf("y=%.4g", yi))
                    end
                end
                axis_readout[ax][] = join(parts, "\n")
            end
            return
        end
        cursor[] = "x=0.0  y=0.0"
        hovered_axis[] = nothing
    end

    on(events(fig).mousebutton) do event
        value_mode[] || return
        (event.button == Makie.Mouse.left &&
         event.action == Makie.Mouse.press) || return
        hovered_axis[] === nothing && return
        p = crosshair_pt[]
        coords = @sprintf("%.6g, %.6g", p[1], p[2])
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
        path = _export_figure(_output_path(output_folder, base, "png"), builder)
        flash_status!("saved $path")
    end
    on(pdf_btn.clicks) do _
        path = _export_figure(_output_path(output_folder, base, "pdf"), builder)
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

function _show_interactive(builder; figsize=(720, 580), fig_name::String="",
                           output_folder="output")
    fig = Figure(; size=figsize)
    plot_grid = GridLayout(fig[1, 1])
    artifacts = builder(plot_grid)
    axes_list = _extract_axes(artifacts)
    _add_controls!(fig, axes_list, builder, fig_name; output_folder,
                   fig_width=figsize[1])
    _LAST_BUILDER[] = builder
    screen = display(fig)
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
    path = _export_figure(target, _LAST_BUILDER[])
    @info "wrote $path"
    return path
end
