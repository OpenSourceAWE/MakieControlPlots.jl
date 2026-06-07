using Pkg
if ! ("ControlSystemsBase" ∈ keys(Pkg.project().dependencies))
    Pkg.activate("examples")
end
using ControlSystemsBase
using MakieControlPlots

P = tf([1.], [1., 1])

fig = bode_plot(P; from=-2, to=2, fig="bode", title="Low pass filter")
