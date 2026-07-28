# load the jld2 file from the data folder and plot it
using MakieControlPlots, LaTeXStrings

p = MakieControlPlots.load(joinpath(@__DIR__, "..", "data", "foc_torque_f1_steps.jld2"))
display(p)

