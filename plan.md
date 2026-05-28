# MakieControlPlots.jl — Plan

## Phase 0 — MWE (single file, no package yet)

`mwes/mwe.jl`: prove the export/interactive split with no duplicated
figure code. Pattern:

```julia
build_plot!(fig) = ...          # adds axis + data to a given Figure

interactive(build_plot!)         # wraps with controls + displays
# Save PNG / Save PDF buttons call:
export_figure("mwe.png", build_plot!)
export_figure("mwe.pdf", build_plot!)
```

Two helpers:

- `interactive(builder)` — `Figure()`, run builder, attach a control
  row (Pan/Zoom/Home/Save PNG/Save PDF), `display`.
- `export_figure(filename, builder)` — `Figure()`, run builder, save
  via GLMakie for `.png` or CairoMakie for `.pdf`. No buttons.

Exports therefore literally cannot contain a button row because the
export path never calls `add_controls!`.

## Phase 1 — Package scaffold

```
Project.toml
src/MakieControlPlots.jl       # module, exports, PlotX struct, display, save, load
src/controls.jl                # interactive(), export_figure(), add_controls!
src/plot.jl                    # plot(...) variants
src/plotx.jl                   # plotx(...)
src/plotxy.jl                  # plotxy(...) (separate from plot.jl for clarity)
src/plot2d.jl                  # plot2d(...) animation
ext/MakieControlPlotsControlSystemsBaseExt.jl   # bode_plot
test/runtests.jl
mwes/mwe.jl
examples/...                   # ported from ControlPlots
```

Project deps: `Makie`, `GLMakie`, `CairoMakie`, `JLD2`,
`LaTeXStrings`, `StaticArraysCore`, `Printf`.

## Phase 2 — Port plot.jl

Method signatures verbatim from ControlPlots. Each public `plot(...)`
method:

1. Builds the `PlotX` struct (so JLD2 save still works).
2. If `disp=true`, calls `interactive(build_plot!)` where
   `build_plot!` constructs the appropriate `Axis` and series on the
   given `Figure`.

For each ControlPlots variant we need an equivalent `build_plot!`
inner function:

- `plot(X, Y::Vector)` — single-series with optional ann/scatter.
- `plot(X, Ys::Vector{<:Union{Vector,Tuple}})` — multi-series + errorbars.
- `plot(X, Y1::Vector{<:Vector}, Y2::Vector{<:Number})` — multi-left + twin-right.
- `plot(X, Y1::Vector{<:Number}, Y2::Vector{<:Number})` — twin-y.

Color palette `[green, grey, red]` from ControlPlots is kept literally
so visuals match.

## Phase 3 — Port plotx.jl

Stacked subplots sharing x-axis. In Makie: one `Figure`, `n` `Axis`es
in `fig[i,1]`, `linkxaxes!`. Hide xtick labels on all but the last.
`yzoom` scales the per-row height by setting figure size on creation.

## Phase 4 — Port plotxy.jl

Single axis, `scatter` toggles between `lines!` and `scatter!`.

## Phase 5 — Port plot2d.jl

State previously held in `let` closures (`lines`, `sc`, `txt`) — keep
the same pattern but key the state per `fig=` name in a `Dict` so
multiple animations can run concurrently. First call (`reltime == 0`)
clears the entry for that figure name.

Updates use observables: store `Observable{Vector{Point2f}}` for the
particle positions and the segment endpoints; subsequent calls write
to those observables instead of rebuilding the scene.

## Phase 6 — Tests + examples + docs

- Copy every `ControlPlots/examples/*.jl` into `examples/` with the
  `using` line swapped; confirm each runs.
- `test/runtests.jl` covers struct construction, save/load round-trip,
  and that PNG/PDF export produces a non-empty file.
- README mirrors ControlPlots' README, with a short note on the
  control-row buttons.

## Open questions to resolve as we go

- Confirm `Makie.DragPan`, `Makie.ScrollZoom`, `Makie.RectangleZoom`
  are usable for the toggle implementation in the targeted Makie
  version; fall back to `Makie.deactivate_interaction!` /
  re-registration if not.
- LaTeX rendering in CairoMakie PDF: should "just work" via
  `LaTeXStrings`, but verify in Phase 1 examples.
- Multiple GLMakie windows: PR #1771 is merged but the ergonomic
  surface (one `Figure` ↔ one window) needs a smoke test before
  relying on it from `fig="name"`.
