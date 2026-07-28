# load the jld2 file from the data folder and plot it
using MakieControlPlots, LaTeXStrings

p = MakieControlPlots.load(joinpath(@__DIR__, "..", "data", "foc_speed_f1_ramp_load_estimator.jld2"))
p.rowgap = 6
p.legendsize = 12
display(p)

