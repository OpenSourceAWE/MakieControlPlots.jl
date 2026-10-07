module MakieControlPlotsControlSystemsBaseExt

using ControlSystemsBase
using MakieControlPlots
using Makie

import MakieControlPlots: bode_plot, _show_interactive

struct BodePlot
    sys
    title::String
    from
    to
    db::Bool
    hz::Bool
    bw::Bool
    linestyle
    show_title::Bool
    fontsize
    fig::String
    phase_offset::Float64
    ref_lines::Bool
    xticks
end

function _frequency_response(sys; from=-1, to=2)
    w = exp10.(LinRange(from, to, 1000))
    mag, phase, w1 = bode(sys, w)
    return w, mag[:], phase[:]
end

_todb(mag) = 20 * log10(mag)

# Frequencies at which the magnitude drops below 1 (0 dB), interpolated linearly in
# log(magnitude) over log(frequency).
function _gain_crossovers(w, mag)
    lm = log10.(mag)
    return [exp10(log10(w[i]) + lm[i] / (lm[i] - lm[i + 1]) * log10(w[i + 1] / w[i]))
            for i in 1:length(w) - 1 if lm[i] >= 0 && lm[i + 1] < 0]
end

# Frequencies at which the phase [deg] crosses -180°, in either direction, interpolated
# linearly over log(frequency).
function _phase_crossovers(w, phase)
    d = phase .+ 180
    return [exp10(log10(w[i]) + d[i] / (d[i] - d[i + 1]) * log10(w[i + 1] / w[i]))
            for i in 1:length(w) - 1 if d[i] != d[i + 1] && sign(d[i]) != sign(d[i + 1])]
end

# `y` at the frequency `f`, interpolated linearly over log(frequency) on the grid `w`.
function _interp_log(w, y, f)
    i = clamp(searchsortedlast(w, f), 1, length(w) - 1)
    return y[i] + (y[i + 1] - y[i]) * log(f / w[i]) / log(w[i + 1] / w[i])
end

function _bode_builder(bp::BodePlot)
    w, mag, phase = _frequency_response(bp.sys; from=bp.from, to=bp.to)
    if bp.hz
        w = w ./ (2π)
    end
    xlabel = bp.hz ? "Frequency [Hz]" : "Frequency [rad/s]"
    mag_yvals = bp.db ? _todb.(mag) : mag
    mag_ylabel = bp.db ? "Magnitude [dB]" : "Magnitude"
    mag_yscale = bp.db ? identity : log10
    line_color = bp.bw ? :black : Makie.wong_colors()[1]
    # `bode` unwraps the phase from the lowest frequency, so it can land a multiple of
    # 360° away from where the -180° stability criterion is usually read.
    phase = phase .+ bp.phase_offset
    return function(layout)
        ax1 = Axis(layout[1, 1]; xscale=log10, xticks=something(bp.xticks, Makie.automatic), yscale=mag_yscale,
                   ylabel=mag_ylabel, ylabelsize=bp.fontsize,
                   xlabelsize=bp.fontsize, xgridvisible=true,
                   ygridvisible=true, xminorgridvisible=true,
                   xminorticksvisible=true,
                   xminorticks=IntervalsBetween(9),
                   yminorgridvisible=!bp.db, yminorticksvisible=!bp.db,
                   yminorticks=IntervalsBetween(9),
                   title=bp.show_title ? bp.title : "",
                   titlesize=bp.fontsize,
                   titlefont=MakieControlPlots.TITLE_FONT)
        ax2 = Axis(layout[2, 1]; xscale=log10, xticks=something(bp.xticks, Makie.automatic), xlabel=xlabel,
                   ylabel="Phase [deg]", xlabelsize=bp.fontsize,
                   ylabelsize=bp.fontsize, xgridvisible=true,
                   ygridvisible=true, xminorgridvisible=true,
                   xminorticksvisible=true,
                   xminorticks=IntervalsBetween(9))
        lines!(ax1, w, mag_yvals; color=line_color, linestyle=bp.linestyle)
        lines!(ax2, w, phase; color=line_color, linestyle=bp.linestyle)
        if bp.ref_lines
            # 0 dB (or a magnitude of 1) and -180°: where the gain and phase margins are read.
            hlines!(ax1, [bp.db ? 0.0 : 1.0]; color=:gray, linestyle=:dot)
            hlines!(ax2, [-180.0]; color=:gray, linestyle=:dot)
            # Gain crossover: the phase margin is read on the phase plot at this line.
            wc = _gain_crossovers(w, mag)
            if !isempty(wc)
                vlines!(ax1, wc; color=:gray, linestyle=:dash)
                vlines!(ax2, wc; color=:gray, linestyle=:dash)
                # The phase margin itself: from -180° up (or down) to the phase at the crossover.
                for f in wc
                    ph = _interp_log(w, phase, f)
                    lines!(ax2, [f, f], [-180.0, ph]; color=:black, linewidth=2)
                    pm = round(Int, ph + 180)
                    text!(ax2, f, (ph - 180) / 2; text=rich("P", subscript("m"), " = $(pm)°"),
                          align=(:left, :center), offset=(6, 0), fontsize=bp.fontsize)
                end
            end
            # The gain margin: at each -180° crossing of the phase, from 0 dB to the magnitude.
            # Its value is -|L| in dB, so a negative one is a lower gain margin: the loop
            # becomes unstable if its gain drops by that much.
            for f in _phase_crossovers(w, phase)
                m_db = _interp_log(w, _todb.(mag), f)
                lines!(ax1, [f, f], bp.db ? [0.0, m_db] : [1.0, exp10(m_db / 20)]; color=:black, linewidth=2)
                gm = round(-m_db; digits=1)
                # Left of the line, on the other side of 0 dB, where the curve is not.
                up = m_db < 0
                text!(ax1, f, bp.db ? 0.0 : 1.0; text=rich("G", subscript("m"), " = $(gm) dB"),
                      align=(:right, up ? :bottom : :top), offset=(-4, up ? 4 : -4),
                      fontsize=bp.fontsize)
            end
        end
        xlims!(ax1, first(w), last(w))
        xlims!(ax2, first(w), last(w))
        linkxaxes!(ax1, ax2)
        hidexdecorations!(ax1; grid=false, ticks=false, minorgrid=false,
                          minorticks=false)
        return (; axes=[ax1, ax2])
    end
end

function _bode_show(bp::BodePlot; output_folder="output", new_screen=true)
    fig_name = isempty(bp.fig) ? "bode" : bp.fig
    _show_interactive(_bode_builder(bp);
                      figsize=(round(Int, 8 * 96), round(Int, 6 * 96)),
                      fig_name, output_folder, new_screen)
    return nothing
end

function bode_plot(sys::Union{StateSpace, TransferFunction}; title="",
                   from=-1, to=1, fig="", db=true, hz=true, bw=false,
                   linestyle=:solid, show_title=true, fontsize=18,
                   output_folder="output", disp=false, new_screen=true,
                   phase_offset=0.0, ref_lines=false, xticks=nothing)
    bp = BodePlot(sys, title, from, to, db, hz, bw, linestyle, show_title,
                  fontsize, fig, phase_offset, ref_lines, xticks)
    disp && _bode_show(bp; output_folder, new_screen)
    return bp
end

function Base.display(bp::BodePlot; new_screen=true)
    _bode_show(bp; new_screen)
    return nothing
end

end
