using MakieControlPlots
using LaTeXStrings

T = 0:0.1:2pi
Ys = [sin.(T) .+ i * 0.1 for i in 1:6]
labels = ["s$i" for i in 1:6]

for k in 1:6
    plotx(T, Ys[1:k]; labels=[labels[1:k]], title="$k legend entries",
          titlesize=20, legendsize=14, fig="many-entries-$k",
          disp=true, new_screen=true)
end
