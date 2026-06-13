using MakieControlPlots

T = 0:0.2:2pi+0.1
POS_Z = sin.(T)
VEL_Z = 5*cos.(T)
ERR_POS = 0.2 .+ 0.1*abs.(randn(length(T)))
ERR_VEL = 0.2 .+ 0.1*abs.(randn(length(T)))
p = plot(T, [(POS_Z, ERR_POS), (VEL_Z, nothing)]; 
         xlabel="time [s]", ylabel="pos [m]", labels=["pos_x", "vel_y"],
         legendsize=16,
         fig="dual-one-axis-error-bars", title="Dual plot with error bars")