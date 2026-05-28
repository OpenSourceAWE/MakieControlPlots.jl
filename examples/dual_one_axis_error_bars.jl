using MakieControlPlots

function plot1(X, Ys::AbstractVector{<:Union{AbstractVector, Tuple}}; xlabel="", ylabel="",
    labels=nothing, xlims=nothing, ylims=nothing, ann=nothing, scatter=false, fig="", ysize=14, disp=false)
end

T = 0:0.2:2pi+0.1
POS_Z = sin.(T)
VEL_Z = 5*cos.(T)
ERR_POS = 0.2 .+ 0.1*abs.(randn(length(T)))
ERR_VEL = 0.2 .+ 0.1*abs.(randn(length(T)))
p = plot(T, [(POS_Z, ERR_POS), (VEL_Z, nothing)];
         xlabel="time [s]", ylabel="pos [m]", labels=["pos_x", "vel_y"])
