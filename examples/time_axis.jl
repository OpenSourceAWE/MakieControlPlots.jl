using Dates
using MakieControlPlots

# Two hours of measurements, one sample per minute, with clock times as X.
# The x axis is labelled with clock times; zoom in to see seconds.
T = DateTime(2026, 11, 13, 9, 0) .+ Minute.(0:120)
t = Dates.value.(T .- first(T)) ./ 60_000   # minutes since the start
Hs = 2.0 .+ 0.5 .* sin.(2pi .* t ./ 60)
Tp = 8.0 .+ 1.0 .* cos.(2pi .* t ./ 45)
p = plotx(T, Hs, Tp; ylabels=["Hs [m]", "Tp [s]"], fig="time-axis",
          title="Time axis")
