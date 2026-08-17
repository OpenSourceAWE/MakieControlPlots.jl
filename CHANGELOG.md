# CHANGELOG

## v0.1.13 17-08-2026

### Added
- Twin y axes in a `plotx` channel: passing a two-element vector as a
  channel's `ylabels` entry draws that channel's last curve against a
  second y axis on the right, labeled by the second entry, and the earlier
  curves against the left one — the same left/right convention
  `plot(X, Y1, Y2)` already uses for `ylabels`. No new keyword argument, so
  `PlotX` structs keep round-tripping through `save`/`load` unchanged and
  existing calls render exactly as before. The right-hand axis label and
  tick labels take their curve's color, both axes are x-linked into the
  stack so they pan and zoom with it, and the channel gets a single legend
  spanning the curves on both axes. A channel with only one curve ignores
  the second label and stays single-axis.

## v0.1.12 28-07-2026

### Added
- `rowgap` keyword to `plotx` — controls the vertical gap, in pixels,
  between stacked subplots (default `18`, matching Makie's own
  `GridLayout` default, so existing calls render unchanged). Passed
  through `PlotX` save/load round-tripping like the other display
  keywords.

## v0.1.11 28-07-2026

### Fixed
- Legends drawn with a non-default `legendsize` kept a frame sized for the
  default: only `labelsize` was passed to Makie, and the patch, row gap,
  padding and patch-label gap come from theme constants that do not track it.
  With a small `legendsize` the 20 px color patch — not the glyphs — set the
  row pitch, so entries looked over-spaced inside an over-large box. That
  geometry now scales with `legendsize` in `plot`, `plotx` and `plotxy`, and
  in the row-height probe `plotx` uses to reserve space for legends, so small
  legends no longer over-reserve window height. Plots that do not override
  `legendsize` are unaffected: the scaling is anchored to the default of 16,
  which reproduces Makie's stock legend metrics exactly.

## v0.1.10 27-07-2026

### Fixed
- `plotx`: the extra window height reserved for legends could be assigned to
  the wrong channel. The legend-overflow probe used to pair legends with axes
  geometrically, but an `axislegend` sits flush with the top of its axis, so
  sub-pixel layout rounding could push it into the neighboring row's band —
  leaving one channel with two legends and another with none, and producing
  bogus growth. The `plotx` builder now reports each channel's legend
  (`nothing` where a channel has none) alongside its axes, so the pairing is
  correct by construction.

## v0.1.9 17-07-2026

### Added
- `plotxy(Xs::AbstractVector{<:AbstractVector}, Ys::AbstractVector{<:AbstractVector}; ...)` —
  plot multiple XY series in one plot. Each element of `Xs` and `Ys` is a
  separate series; the optional `legend` keyword provides per-series labels.
- `linestyle` keyword to `plotxy` — sets the line style (e.g. `:solid`,
  `:dash`, `:dot`). Accepts a single style for all series or a vector of
  styles, one per series.

### Fixed
- `plotx`: the aspect ratio of saved plots could be wrong

## v0.1.8 15-07-2026

### Fixed
- `plotx`: a channel's legend (e.g. many labeled lines, or a title/x-label
  competing for space) could extend past that channel's own axis line,
  overlapping the x-axis in the interactive window. The window now grows by
  exactly the amount needed to keep every legend within its axis panel,
  without padding channels that already fit.

### Added
- `examples/many_entries_with_title.jl` — a titled `plotx` channel with 1 to
  6 legend entries, used to exercise the fix above.
- `examples/show_example.jl` — loads and displays a saved `.jld2` plot from
  the `data/` folder.
- `CLAUDE.md` — guidance for AI coding agents working in this repository.

### Changed
- `bin/release`: now aborts if the working tree has uncommitted changes, or
  if the current branch has commits not yet pushed to its upstream, instead
  of only printing a warning.

## v0.1.7 12-07-2026

### Added
- `plotxy(X, Y; ..., aspect=nothing)` — pass `aspect=:equal` to give the X and
  Y axes equal scaling 

### Changed
- `PlotX` struct gained an `aspect` field 
- README: documented the new `aspect` parameter for `plotxy`.

## v0.1.6 05-07-2026

### Added
- `plot(Y::AbstractMatrix)` and `plot(X, Y::AbstractMatrix)` — each column of
  the matrix is plotted as a separate line. 
- Extended precompile workload — all plotting functions (`plot`, `plotx`,
  `plotxy`) are now exercised during precompilation, including GLMakie
  rendering paths (wrapped in `try`/`catch` for headless environments).
- Time-to-first-plot benchmark (`test/ttfp.jl`).
- Developer tooling: JET analysis script (`bin/jetls`),
  `.JETLSConfig.toml.default`, `.markdownlint.json`.

### Changed
- Type annotations added throughout (`xscale::Symbol`, `mode[]::Symbol`,
  `event.button::Makie.Mouse.Button`, etc.) to eliminate method-overwrite
  warnings from Julia's compiler.
- Exports in `MakieControlPlots.jl` sorted alphabetically.
- README: added full function signatures for the new `Matrix` methods.
- Cleaned up obsolete `plan.md` and `testing.md` files.

## v0.1.5 20-06-2026

### Added
- `wait_for_figures()` — blocks execution until all interactive figure windows
  have been closed by the user. Polls every 0.2 s to avoid busy-waiting.
- `install_examples(add_packages=true; overwrite=true)` — copies packaged
  example scripts to the current working directory and can install optional
  example dependencies (`ControlSystemsBase`, `LaTeXStrings`).
- Example script `examples/wait_for_figures.jl` demonstrating interactive
  figures that wait for user dismissal.
- `wait_for_figures` entry in the example menu.

### Changed
- README: updated install instructions from GitHub URL to registry package name
  (`pkg"add MakieControlPlots"`), added documentation for `close()` and
  `wait_for_figures()`.

### Internal
- Added `_LAST_FIG` and `_LAST_SCREEN` refs in `controls.jl` for tracking the
  most recently displayed figure and its screen.

## v0.1.4 19-06-2026

### Added
- `migrate_legacy_plotx_file(input_path; output_path=nothing)` — migrate old
  `.jld2` files to the current versioned format.
- `xticks` keyword parameter to `plot`, `plotx`, `plotxy`, and `Base.display`.
- `xscale` keyword parameter (`:identity`, `:log10`, `:log2`, `:ln`) to `plot`,
  `plotx`, `plotxy`, and `Base.display`.
- `label` keyword parameter to `plot` — adds a legend entry for single-line
  plots.
- `grid` keyword parameter to `plot`, `plotx`, `plotxy`, and `Base.display` —
  toggles grid line visibility.
- `LINE_WIDTH` constant — applied consistently to all line plots.
- `zoom` field to `Plot2DState` for proper plot rebuild detection when the
  zoom flag changes.

### Changed
- **`PlotX` save/load now uses a versioned Dict format** instead of raw struct
  serialization. Old `.jld2` files saved with v0.1.3 or earlier are still
  readable via `load()`, but `save()` writes the new format. Use
  `migrate_legacy_plotx_file(path)` to upgrade old files in-place.
- `PlotX` struct gained `xscale`, `grid`, `label`, and `xticks` fields. The
  Dict format ensures forwards/backwards compatibility for future field additions.
- Default `labelsize` and `legendsize` reduced from 20 to 16; `titlesize`
  reduced from 20 to 18.
- `plot2d` time annotation uses relative coordinates (`space=:relative`) when
  zoomed, preventing the label from drifting off-screen.

### Fixed
- XY plot window width increased from 576 to 640 px so the cursor coordinate
  label fits beside the buttons instead of wrapping to a second row.
- Label positions in `plot2d` — the time annotation is now anchored at a
  stable relative position `(0.02, 0.98)` when zoomed without explicit `xy`.
- Long status messages (e.g. save paths wider than cursor text) now
  temporarily collapse the button column via `colsize!` so the info label
  doesn't overflow/wrap.
- `GridLayoutBase` added as a direct dependency.

### Removed
- Unused `save_sample` variable in `controls.jl`.

## v0.1.3 18-06-2026

### Added
- `close(fig_name::String)` function — matches Matplotlib's `plt.close`:
  close a specific figure by name, or `close("all")` to close all figures.

### Fixed
- `plot2d` now correctly rebuilds the plot when the screen has been closed
  externally, preventing errors on subsequent display calls.

## v0.1.2 13-06-2026

### Added
- `legendsize` keyword parameter to `plot`, `plotx`, `plotxy`, and `Base.display`.
- `titlesize` keyword parameter to `plot`, `plotx`, `plotxy`, and `Base.display`.
- `labelsize` keyword parameter to `plot2d`, applied to axis labels and the
  time annotation text.
- Continuous integration workflow (`.github/workflows/CI.yml`).
- Comprehensive README with usage documentation, badges, and example screenshots.
- Documentation images for all example types.

### Changed
- `PlotX` struct now stores `legendsize::Int` and `titlesize::Int` fields for
  persistence across save/load cycles.
- Cleaned up test imports by hoisting common imports (`CairoMakie`, `Figure`,
  `Base.display`) to the top-level `@testset` block.

## v0.1.1 09-06-2026

### Added
- README with usage documentation.
- Test suite (`test/runtests.jl`).
- REUSE-compliant licensing (`REUSE.toml`, `LICENSES/`) and a top-level
  `LICENSE` for Julia registry AutoMerge.

### Changed
- Raised Makie compat: Makie 0.23/0.24, CairoMakie 0.14/0.15, GLMakie 0.12/0.13.
- Reordered the control buttons to Home, Zoom, Pan.
- Corrected the package UUID.

### Fixed
- Saving a plot (PNG/PDF buttons or `savefig`) now keeps the current zoom and
  pan, so the exported image matches what is shown on screen.
- Plot windows and exported images now use a 4:3 aspect ratio matching
  ControlPlots.jl. The default plot size is 640×480.
- Zoom and Home reset behavior.
- Automatic display in a new window.

## v0.1.0

### Added
- Initial release: `plot`, `plotx`, `plotxy`, `plot2d`, `save`/`load`,
  `savefig`, and `bode_plot` (via the ControlSystemsBase extension), with an
  interactive GLMakie window offering Home/Zoom/Pan controls and PNG/PDF export.
