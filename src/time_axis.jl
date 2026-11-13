# Time axes: `plot` and `plotx` accept a vector of `DateTime` (or `Date`) as X.
#
# The figure itself is drawn in plain `Float64` seconds since the first sample
# (`t0`), so zoom, pan, the cursor readout, the value markers and the automatic
# legend placement keep working on ordinary numbers. Only the tick labels and
# the cursor/clipboard texts translate those seconds back into clock times.
# The `PlotX` struct keeps the original `DateTime` vector, so `display`, `save`
# and `load` round-trip unchanged.

const _TimeVector = AbstractVector{<:Union{DateTime, Date}}

# Axes that show time, mapped to their `t0`; read by the controls to format x.
const _TIME_ORIGINS = WeakKeyDict{Any, DateTime}()

_seconds(t, t0::DateTime) = Dates.value(DateTime(t) - t0) / 1000
_datetime(x::Real, t0::DateTime) = t0 + Millisecond(round(Int64, 1000x))

_is_time(x) = x isa Union{DateTime, Date}

"""
    _time_x(X, xlims) -> (X, xlims, t0)

Convert a time vector `X` (and `xlims` given as times) to seconds since the
first sample `t0`. For any other `X` return the inputs unchanged and
`t0 = nothing`.
"""
function _time_x(X::_TimeVector, xlims)
    t0 = DateTime(first(X))
    Xs = Float64[_seconds(t, t0) for t in X]
    if !isnothing(xlims) && _is_time(xlims[1])
        xlims = (_seconds(xlims[1], t0), _seconds(xlims[2], t0))
    end
    return Xs, xlims, t0
end
_time_x(X, xlims) = (X, xlims, nothing)

# Candidate tick spacings, smallest first; ticks fall on round clock times.
const _TIME_STEPS = Dates.Period[
    Millisecond(1), Millisecond(2), Millisecond(5), Millisecond(10),
    Millisecond(20), Millisecond(50), Millisecond(100), Millisecond(200),
    Millisecond(500), Second(1), Second(2), Second(5), Second(10), Second(15),
    Second(30), Minute(1), Minute(2), Minute(5), Minute(10), Minute(15),
    Minute(30), Hour(1), Hour(2), Hour(3), Hour(6), Hour(12), Day(1), Day(2),
    Day(7), Day(14), Day(30), Day(60), Day(91), Day(182), Day(365)]

_period_seconds(p::Dates.Period) = Dates.value(Millisecond(p)) / 1000

function _time_format(step_s, ticks::AbstractVector{DateTime})
    step_s >= 86400 && return dateformat"yyyy-mm-dd"
    multi_day = Date(first(ticks)) != Date(last(ticks))
    fmt = step_s < 1  ? "HH:MM:SS.sss" :
          step_s < 60 ? "HH:MM:SS" : "HH:MM"
    return DateFormat(multi_day ? "mm-dd " * fmt : fmt)
end

"""
    _time_ticks(t0) -> Function

Tick function for `Axis.xticks`: given the visible range in seconds since `t0`
it returns tick positions on round clock times and their labels.
"""
function _time_ticks(t0::DateTime)
    return function (vmin, vmax)
        (isfinite(vmin) && isfinite(vmax) && vmax > vmin) ||
            return (Float64[], String[])
        target = (vmax - vmin) / 6
        idx = findfirst(p -> _period_seconds(p) >= target, _TIME_STEPS)
        step = _TIME_STEPS[something(idx, length(_TIME_STEPS))]
        t = ceil(_datetime(vmin, t0), step)
        tend = _datetime(vmax, t0)
        ticks = DateTime[]
        while t <= tend
            push!(ticks, t)
            t += step
        end
        isempty(ticks) && return (Float64[], String[])
        fmt = _time_format(_period_seconds(step), ticks)
        return ([_seconds(t, t0) for t in ticks], [Dates.format(t, fmt) for t in ticks])
    end
end

"""
    _time_axis!(ax, t0)

Label the x axis of `ax` with clock times relative to `t0`. Does nothing when
`t0` is `nothing` or the caller passed explicit `xticks`.
"""
function _time_axis!(ax, t0, xticks=nothing)
    isnothing(t0) && return nothing
    isnothing(xticks) && (ax.xticks = _time_ticks(t0))
    _TIME_ORIGINS[ax] = t0
    return nothing
end

# x as shown in the cursor readout and copied to the clipboard.
function _format_x(ax, x)
    t0 = get(_TIME_ORIGINS, ax, nothing)
    isnothing(t0) && return @sprintf("%.4g", x)
    isfinite(x) || return string(x)
    return Dates.format(_datetime(x, t0), dateformat"yyyy-mm-ddTHH:MM:SS.sss")
end
