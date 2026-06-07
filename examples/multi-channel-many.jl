using MakieControlPlots

T = 0:0.1:2pi
Y1 = sin.(T)
Y2 = cos.(T)
Y3 = 0.2*sin.(2T)
Y4 = 0.2*cos.(2T)
Y5 = 0.2*sin.(3T)
Y6 = 0.2*cos.(3T)
Y7 = 0.2*sin.(4T)
Y8 = 0.2*cos.(4T)
Y9 = 0.2*sin.(5T)
p=plotx(T, Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8, Y9; ylabels=["sin","cos", "0.2sin(2T)", "0.2cos(2T)", 
        "0.2sin(3T)", "0.2cos(3T)", "0.2sin(4T)", "0.2cos(4T)", "0.2cos(4T)", "0.2sin(5T)"], 
        ysize=11, yzoom=0.7, fig="multi-channel-many", title="Multiple channels, many plots")
