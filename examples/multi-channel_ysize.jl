using MakieControlPlots

T = 0:0.1:2pi
X = sin.(T)
Y = cos.(T)
p = plotx(T, X, Y; 
        ylabels=["sin","cos"], fig="2-chan", ysize=8, title="Dual channel, smaller y labels")