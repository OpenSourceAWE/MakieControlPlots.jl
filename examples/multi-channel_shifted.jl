using MakieControlPlots

T = 2pi:0.1:4pi
X = sin.(T)
Y = cos.(T)
plotx(T, X, Y; ylabels=["sin","cos"], fig="2-chan")
