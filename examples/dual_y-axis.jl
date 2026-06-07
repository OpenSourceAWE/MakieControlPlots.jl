using MakieControlPlots

T = 0:0.05:2pi+0.1
POS_Z = sin.(T)
VEL_Z = 5*cos.(T)
plot(T, POS_Z, VEL_Z; 
     xlabel="time [s]", ylabels=["pos_z [m]", "vel_z [m/s]"], labels=["pos_z", "vel_z"],
     fig="dual-y-axis")
