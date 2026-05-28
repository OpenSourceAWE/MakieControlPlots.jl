# MakieControlPlots.jl — Requirements

## Goal

A drop-in replacement for `ControlPlots.jl` whose public API is identical
(function names, argument names, default values), but whose backend is
Makie instead of PyPlot/matplotlib.

Switching a project from `ControlPlots` to `MakieControlPlots` must be a
single-line change at the `using` site.

## Public API (1-to-1 with ControlPlots)

Exported symbols:

- `plot` — single-series, dual-y, multi-series, scatter, errorbars
- `plotx` — oscilloscope-style stacked plot with shared x-axis
- `plotxy` — x-y scatter/line
- `plot2d` — animated 2D particle/segment view (with `seg` overload)
- `savefig(filename)` — save the current figure
- `save(filename, p)` / `load(filename)` — JLD2 persistence of plot data
- `bode_plot` — extension stub (ControlSystemsBase)

All keyword arguments (`xlabel`, `ylabels`, `labels`, `xlims`, `ylims`,
`ann`, `scatter`, `fig`, `ysize`, `yzoom`, `disp`, etc.) must keep the
same names and semantics.

## Backend behavior

- **Interactive display:** GLMakie. A window per `fig=` name.
- **PNG export:** GLMakie (the on-screen renderer).
- **PDF export:** CairoMakie, opened only at save time so GLMakie keeps
  owning the live window.

## Interactive features

Each interactive figure has a control row with:

- **Pan** toggle — enables/disables drag-pan interaction
- **Zoom** toggle — enables/disables rectangle + scroll zoom
- **Home** — `reset_limits!` on every axis in the figure
- **Save PNG** — writes a PNG of the figure (buttons not shown)
- **Save PDF** — writes a PDF of the figure (buttons not shown)

## Export invariants

The PDF/PNG file must contain only the data axes — no Pan/Zoom/Home/Save
button row. This is achieved by a single figure-builder function that
the interactive path wraps in controls and the export path invokes on a
fresh figure. There must be **no duplicated figure-construction code**
between the interactive and export paths.

## Other requirements

- Multiple plot windows supported via `fig="name"` (separate `Figure`s
  in separate GLMakie windows).
- LaTeX strings (`LaTeXStrings.jl`) accepted in any label argument.
- `plot2d` animations: state is carried across calls keyed by `fig`
  name; first call (`reltime == 0.0`) re-initializes.
- Returned `PlotX` structs are storable via `save`/`load` (JLD2) and
  re-displayable via `display(::PlotX)`.

## Non-goals

- No 3D plotting.
- No new keyword arguments beyond ControlPlots' surface (additions are
  allowed only if they are strictly optional and ControlPlots-callers
  keep working unmodified).
