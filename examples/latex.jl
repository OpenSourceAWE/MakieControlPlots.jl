using MakieControlPlots, LaTeXStrings

X = 0:0.1:2pi
Y = sin.(X)
p = plot(X, Y, xlabel=L"\alpha = [0..2\pi]", ylabel="sin", fig="latex", title="Use LaTeX for x-axis label")
