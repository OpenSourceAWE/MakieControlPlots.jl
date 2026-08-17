using MakieControlPlots

T = 0:0.05:2pi
FORCE = 300 .+ 100*sin.(2T)
POS_Z = sin.(T)
VEL_Z = 5*cos.(T)

# The second channel's `ylabels` entry is a two-element vector, which gives that
# channel a second y axis on the right: its last curve (`vel_z`) is drawn
# against it, the earlier ones against the left axis.
p = plotx(T, FORCE, [POS_Z, VEL_Z];
          ylabels=["force [N]", ["pos_z [m]", "vel_z [m/s]"]],
          labels=[nothing, ["pos_z", "vel_z"]],
          fig="multi-channel-twin", title="Twin y-axis in one channel",
          titlesize=20, legendsize=18)
