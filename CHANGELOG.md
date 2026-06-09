# CHANGELOG

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
- Plot windows and exported images now use a 4:3 aspect ratio matching
  ControlPlots.jl. The default plot size is 640×480.
- Zoom and Home reset behavior.
- Automatic display in a new window.

## v0.1.0

### Added
- Initial release: `plot`, `plotx`, `plotxy`, `plot2d`, `save`/`load`,
  `savefig`, and `bode_plot` (via the ControlSystemsBase extension), with an
  interactive GLMakie window offering Home/Zoom/Pan controls and PNG/PDF export.
