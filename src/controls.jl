const _LAST_BUILDER = Ref{Any}(nothing)

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
    grid = GridLayout(fig[2, 1]; tellwidth=false, tellheight=true)
    pan_btn  = Button(grid[1, 1]; label="Pan: off")
    zoom_btn = Button(grid[1, 2]; label="Zoom: on")
    home_btn = Button(grid[1, 3]; label="Home")
    png_btn  = Button(grid[1, 4]; label="Save PNG")
    pdf_btn  = Button(grid[1, 5]; label="Save PDF")

    for ax in axes_list
        ax.panbutton[] = Makie.Mouse.left
    end
    mode = Ref(:zoom)
    apply_mode! = function()
        for ax in axes_list
            _set_interaction_active!(ax, :dragpan,       mode[] == :pan)
            _set_interaction_active!(ax, :rectanglezoom, mode[] == :zoom)
        end
        pan_btn.label  = mode[] == :pan  ? "Pan: on"  : "Pan: off"
        zoom_btn.label = mode[] == :zoom ? "Zoom: on" : "Zoom: off"
    end
    apply_mode!()

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
        _export_figure(joinpath(pwd(), "$(base).png"), builder)
    end
    on(pdf_btn.clicks) do _
        _export_figure(joinpath(pwd(), "$(base).pdf"), builder)
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
    @info "wrote $filename"
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
    return _export_figure(filename, _LAST_BUILDER[])
end
