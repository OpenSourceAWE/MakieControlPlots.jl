# load the jld2 file from the data folder and plot it
using MakieControlPlots, LaTeXStrings

p = MakieControlPlots.load(joinpath(@__DIR__, "..", "data", "dynamic_sinus_test_heading_tracking.jld2"))
display(p)

# TODO
# if I save this file as png or pdf, the aspect ratio is not preserved. Please fix this in MakieControlPlots.save function.
