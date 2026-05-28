using MakieControlPlots

T = 0:0.1:2pi
Y1 = sin.(T)
Y2 = cos.(T)
Y3 = 0.2*sin.(2T)
Y4 = 0.2*cos.(2T)
Y5 = 0.2*sin.(3T)
Y6 = 0.2*cos.(3T)
Y7 = 0.2*sin.(4T)
plotx(T, Y1, Y2, Y3, Y4, Y5, Y6, Y7; ylabels=["sin","cos", "0.2sin(2T)", "0.2cos(2T)", "0.2sin(3T)", "0.2cos(3T)", "0.2sin(4T)", "0.2cos(4T)"],
      yzoom=0.9, fig="multi-channel")
