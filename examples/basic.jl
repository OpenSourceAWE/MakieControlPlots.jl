using MakieControlPlots

X = 0:0.1:2pi
Y = sin.(X)
p = plot(X, Y; xlabel="X", ylabel="sin", title="Sinus", fig="basic")