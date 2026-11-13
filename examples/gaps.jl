using MakieControlPlots

# Measured data with dropouts: samples that are missing are stored as `nothing`.
# plot and plotx replace `nothing` with NaN, which is drawn as a gap in the line.
T = 0:0.1:2pi
X = Union{Float64, Nothing}[sin(t) for t in T]
Y = Union{Float64, Nothing}[cos(t) for t in T]
X[15:20] .= nothing
Y[40:45] .= nothing
p = plotx(T, X, Y; ylabels=["sin", "cos"], fig="gaps",
          title="Two channels with gaps")
