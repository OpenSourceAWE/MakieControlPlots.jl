using MakieControlPlots

T = 0:0.1:2pi
X = sin.(T)
Y = cos.(T)
p = plotx(T, X, Y; 
        ylabels=["sin","cos"], fig="multi-channel-ysize", ysize=8, title="Dual channel, smaller y labels")