# MakieControlPlots.jl — Testing

## Phase 0: minimum working example (mwe.jl)

Located at `mwes/mwe.jl`. Run with:

```
julia --project=. -i mwes/mwe.jl
```

(`-i` so the async animation loop keeps running.)

What to verify by hand:

1. A GLMakie window opens with a 2D scene: a blue line from (0,0) to a
   moving tip, red scatter dots, and a `t=… s` label that follows the
   tip.
2. The tip moves continuously upward and to the right (the async loop
   is updating `state.pos` / `state.label_text` / `state.label_pos`).
3. A row of 5 buttons sits under the axis: Pan, Zoom, Home, Save PNG,
   Save PDF.
4. Mouse-drag pans, scroll-wheel zooms — by default.
5. Click **Pan**: dragging no longer pans. Click again: pan returns.
6. Click **Zoom**: scroll wheel + rectangle zoom stop. Click again:
   zoom returns.
7. Pan/zoom around mid-animation, then click **Home**: original
   limits restored, animation still running.
8. Click **Save PNG** while the animation is running: `mwe.png`
   appears in the cwd. It must contain the data axes only (no button
   row) and must capture the **frame as it was at click-time**
   (current tip position + matching `t=...` label). The live GLMakie
   window must stay open.
9. Click **Save PDF**: `mwe.pdf` appears in the cwd. Same conditions.
10. After the animation loop completes (around 20 s), the state is
    reset (t=0) — the line snaps back to (0,0)→(1,0), confirming the
    `reltime == 0.0` reset path.

Steps 8 and 9 are the load-bearing ones: they prove
(a) the single-source-of-truth builder works (no duplicate fig code,
no buttons in exports), and
(b) the live frame is what gets exported (observables are shared
between the live figure and the freshly-built export figure).

## Phase 1: API parity smoke tests

For each example in `ControlPlots.jl/examples/`, copy it into
`examples/` here, change `using ControlPlots` to
`using MakieControlPlots`, and confirm it runs and looks visually
equivalent. Examples to cover:

- `simple.jl`, `basic.jl` — single curve, labels, fig name
- `multi-channel.jl`, `multi-channel-many.jl` — `plotx` stacked
- `dual_y-axis.jl`, `dual_y-axis-3.jl` — twin-y plots
- `dual_one_axis.jl`, `dual_one_axis_error_bars.jl` — multi-series + errorbars
- `plotxy.jl` — x-y plot
- `latex.jl` — `LaTeXStrings` in labels
- `plot2d.jl`, `plot2d-seg.jl` — animations
- `multi-channel_shifted.jl`, `multi-channel_ysize.jl` — `yzoom`, `ysize`

## Phase 2: unit tests

`test/runtests.jl` should at minimum:

- Construct a `PlotX` from each `plot*` variant with `disp=false` and
  check the struct's fields.
- Round-trip a `PlotX` through `save`/`load`.
- Build a figure via the public API and call the export helper, then
  assert the resulting PNG / PDF file exists and is non-empty.

Visual correctness is not tested automatically — that is what the MWE
and copied examples are for.

## Phase 3: regression

Once `MakieControlPlots` is wired into a downstream package (e.g.
`KiteViewers.jl`), run that package's own visual tests as a final
check.
