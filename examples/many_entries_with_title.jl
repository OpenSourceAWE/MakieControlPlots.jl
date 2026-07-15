using MakieControlPlots
using LaTeXStrings

T = 0:0.1:2pi
Ys = [sin.(T) .+ i*0.1 for i in 1:6]
labels = ["s$i" for i in 1:6]
p = plotx(T, Ys; labels=[labels], title="Titled many-entry legend", titlesize=20, legendsize=14, disp=true, new_screen=true)
savefig("check_titled_many.png"; output_folder="output")
p
