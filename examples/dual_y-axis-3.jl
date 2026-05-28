using MakieControlPlots

T = 0:0.05:2pi+0.1
POS_Z = sin.(T)
VEL_Z = 5*cos.(T)
CTRL = 0.1*sign.(5*cos.(T))
p=plot(T, [POS_Z, CTRL], VEL_Z; 
       xlabel="time [s]", ylabels=["pos_z [m]", "vel_z [m/s]"], labels=["pos_z", "ctrl", "vel_z"],
       title="Dual y-axis, three plots")
