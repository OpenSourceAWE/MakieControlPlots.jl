using MakieControlPlots

T = 0:0.05:2pi+0.1
X = sin.(T)
Y1 = cos.(3T)
Y2 = cos.(4T)
p = plotxy([X, X], [Y1, Y2], fig="dual xy-plot", xlabel="X", ylabel="Y", title="XY plot",
           legend=["cos(3T)", "cos(4T)"], linestyle=[:solid, :dash], legendsize=16)