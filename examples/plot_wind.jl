using Dates
using MakieControlPlots
using Random

# Synthetic wind speed for October 2026, one sample per hour: uniform random
# values between 0 and 15 m/s, smoothed with a first-order low-pass filter.
Random.seed!(42)
T = DateTime(2026, 10, 1):Hour(1):DateTime(2026, 11, 1)
raw = 15 .* rand(length(T))

tau = 12.0          # filter time constant [h]
alpha = 1 / (1 + tau)
v = similar(raw)
v[1] = raw[1]
for i in 2:length(raw)
    v[i] = v[i-1] + alpha * (raw[i] - v[i-1])
end
# Filtering narrows the spread around the mean; stretch it back to 0..15 m/s.
v = 15 .* (v .- minimum(v)) ./ (maximum(v) - minimum(v))

p = plot(collect(T), v; xlabel="date", ylabel="wind speed [m/s]",
         title="Wind speed, October 2026", fig="wind")
