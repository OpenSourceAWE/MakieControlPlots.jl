using MakieControlPlots

X = 2pi:0.1:4pi
Y = sin.(X)
p = plot(X, Y; title="Shifted x-axis")
