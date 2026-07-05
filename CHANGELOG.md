# CHANGELOG

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
