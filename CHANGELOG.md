# CHANGELOG

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
