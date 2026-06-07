using MakieControlPlots

T = 2pi:0.1:4pi
X = sin.(T)
Y = cos.(T)
p = plotx(T, X, Y; ylabels=["sin","cos"], fig="multi-channel-shifted",
          title="Dual channel plot, shifted x-axis")