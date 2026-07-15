# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this package is

MakieControlPlots.jl is a drop-in replacement for
[ControlPlots.jl](https://github.com/aenarete/ControlPlots.jl): identical
public API (function names, keyword argument names and defaults), but
rendered with Makie instead of PyPlot/matplotlib. Switching a project from
`ControlPlots` to `MakieControlPlots` must remain a single-line `using`
change — see `requirements.md` for the full, authoritative requirements
(public API surface, backend behavior, export invariants). Read it before
changing any exported function's signature or default.

Interactive windows use GLMakie; headless PNG/PDF export falls back to
CairoMakie. No Python/matplotlib dependency.

## Common commands

```bash
./bin/install          # Pkg.instantiate + precompile for both the main
                        # project and examples/
./bin/run_julia         # julia --project -i, with Revise loaded and a
                        # menu() helper for examples/menu.jl
julia --project -e 'using Pkg; Pkg.test()'      # run the full test suite
xvfb-run julia --project -e 'using Pkg; Pkg.test()'   # headless (as CI does)
./bin/jetls              # run JETLS static analysis over src/, logs to output/
./bin/release             # tag+notify JuliaRegistrator (checks CHANGELOG/Project version match)
```

Run a single testset by editing/filtering in `test/runtests.jl` (it's one
flat `@testset "MakieControlPlots"` with nested testsets) or with:

```bash
julia --project -e 'using Pkg; Pkg.test(; test_args=["some filter"])'
```

There's no built-in filter mechanism beyond commenting out testsets — the
suite is small enough that it's normally run in full. `test/ttfp.jl` is a
standalone time-to-first-plot benchmark, run directly with `time ./test/ttfp.jl`,
not part of `Pkg.test()`.

CI (`.github/workflows/CI.yml`) runs on Julia 1.11 and 1.12 under `xvfb-run`
(GLMakie needs a display even for "headless" tests).

## Architecture

### The builder pattern (core invariant)

Every plotting function (`plot`, `plotx`, `plotxy`, `plot2d`, `bode_plot`)
follows the same shape, and this must not be duplicated or diverged from:

1. The public function always constructs and returns a `PlotX` struct
   (`BodePlot` for the extension) describing the plot, regardless of whether
   anything is displayed.
2. When `disp=true`, it also builds a closure — `builder(layout) -> (; axes=[...])`
   — that draws into a given `GridLayout` and returns the created axes. This
   closure is the **single source of truth for figure content**.
3. `_show_interactive` (src/plot.jl) wraps that builder in a real `Figure`,
   adds the control row (`_add_controls!`), and displays it in a GLMakie
   window.
4. `_export_figure` (src/plot.jl) invokes the *same* builder closure on a
   fresh, control-free `Figure`, optionally copying over the current
   zoom/pan limits from the live axes (`_copy_limits!`) before saving via
   CairoMakie.

Because both paths call the same `builder`, PNG/PDF exports never contain
the Pan/Zoom/Home/Save button row, and there is no separate
"export rendering" code path to keep in sync — this is a load-bearing
invariant from `requirements.md`, not just style.

`_LAST_BUILDER[]`, `_LAST_FIGSIZE[]`, `_LAST_AXES[]` (module-level `Ref`s in
`src/controls.jl`) track the most recently displayed plot so `savefig()` can
re-export it without arguments.

### File layout

- `src/MakieControlPlots.jl` — module setup, exports, the `PlotX` struct,
  versioned save/load (JLD2), `install_examples`. `include` order matters
  (`controls.jl` before the `plot*.jl` files that use its helpers).
- `src/controls.jl` — everything backend/UI: the control row
  (`_add_controls!`), pan/zoom/value-inspector mouse interaction,
  `_show_interactive`, `_export_figure`, screen management (`close`,
  `_SCREENS`), `savefig`, `wait_for_figures`. This is where new interactive
  features go.
- `src/plot.jl`, `src/plotx.jl`, `src/plotxy.jl`, `src/plot2d.jl` — one
  module-level `function` per method of the corresponding public API,
  dispatching on argument shape (e.g. `plot(Y::AbstractVector)`,
  `plot(X, Y::AbstractMatrix)`, `plot(X, Y1, Y2)` for dual y-axis, etc.).
  Each defines its own `builder` closure inline.
- `src/precompile.jl` — `PrecompileTools` workload exercising the plotting
  functions (including GLMakie paths, wrapped in `try`/`catch` since CI/dev
  environments may be headless) to cut time-to-first-plot.
- `ext/MakieControlPlotsControlSystemsBaseExt.jl` — package extension
  providing `bode_plot`, active only when `ControlSystemsBase` is loaded.
  Follows the same builder pattern via `_show_interactive`, imported from the
  parent module.
- `examples/` — runnable example scripts, also copied out to user projects by
  `install_examples`; `examples/menu.jl` is an interactive picker (used by
  `bin/run_julia`'s `menu()` helper).
- `mwes/` — minimal reproducers for debugging, not part of the package.

### `PlotX` persistence (versioned dict format)

`PlotX` is not serialized as a raw struct. `save`/`load` in
`src/MakieControlPlots.jl` convert to/from a `Dict{Symbol,Any}` tagged with
`__version__ = _PLOTX_SERIAL_VERSION`, so old `.jld2` files can always be
loaded by filling in defaults for fields that didn't exist yet
(`_reconstruct_plotx`). Legacy files saved before this scheme (v0.1.3 and
earlier, raw-struct format) are handled via `JLD2.Upgrade` +
`JLD2.rconvert(::Type{PlotX}, ...)`, and can be rewritten into the current
format with `migrate_legacy_plotx_file`.

**When adding a field to `PlotX`:** add it to the struct, to `save`'s `Dict`,
to `_reconstruct_plotx`, to `JLD2.rconvert`, and bump
`_PLOTX_SERIAL_VERSION`. Missing any of these breaks either round-tripping
or backward compatibility with older saved files.

### `Base.display(::PlotX)` dispatch

`PlotX.type` (an `Int`, 1–5) records which public function produced the
struct, since `PlotX` is one struct shared across all plot kinds. `type`
determines how `Base.display(p::PlotX)` (bottom of
`src/MakieControlPlots.jl`) re-dispatches to `plot`/`plotx`/`plotxy` with
`disp=true` when a saved/loaded plot is redisplayed.

### Versioning workflow

`CHANGELOG.md` top section's version (`## vX.Y.Z ...`) must match
`Project.toml`'s `version` before `./bin/release` will run — it fails fast
on mismatch rather than posting a release with stale notes.
