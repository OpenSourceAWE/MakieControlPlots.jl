using MakieControlPlots

T = 0:0.1:2pi
Y1 = sin.(T)
Y2 = 0.2*sin.(2T)
Y = cos.(T)
p = plotx(T, [Y1, Y2], Y; ylabels=["sin","cos"], labels=[["Y1","Y2"]], 
         fig="multi-channel-dual", title="multi-channel-dual.jl")
