using MakieControlPlots

X = 0:0.1:2pi
Y = sin.(X)
p = plot(X, Y; fig="simple", title="Simple plot")