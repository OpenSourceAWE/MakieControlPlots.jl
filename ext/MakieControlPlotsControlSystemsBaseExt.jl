module MakieControlPlotsControlSystemsBaseExt

using ControlSystemsBase
using MakieControlPlots
using Makie

import MakieControlPlots: bode_plot, _show_interactive

function _frequency_response(sys; from=-1, to=2)
    w = exp10.(LinRange(from, to, 1000))
    mag, phase, w1 = bode(sys, w)
    return w, mag[:], phase[:]
end

_todb(mag) = 20 * log10(mag)

function bode_plot(sys::Union{StateSpace, TransferFunction}; title="",
                   from=-1, to=1, fig=true, db=true, hz=true, bw=false,
                   linestyle=:solid, show_title=true, fontsize=18)
    w, mag, phase = _frequency_response(sys; from, to)
    if hz
        w = w ./ (2π)
    end
    xlabel = hz ? "Frequency [Hz]" : "Frequency [rad/s]"
    mag_yvals = db ? _todb.(mag) : mag
    mag_ylabel = db ? "Magnitude [dB]" : "Magnitude"
    mag_yscale = db ? identity : log10
    line_color = bw ? :black : Makie.wong_colors()[1]

    builder = function(layout)
        ax1 = Axis(layout[1, 1]; xscale=log10, yscale=mag_yscale,
                   ylabel=mag_ylabel, ylabelsize=fontsize,
                   xlabelsize=fontsize, xgridvisible=true,
                   ygridvisible=true)
        ax2 = Axis(layout[2, 1]; xscale=log10, xlabel=xlabel,
                   ylabel="Phase [deg]", xlabelsize=fontsize,
                   ylabelsize=fontsize, xgridvisible=true,
                   ygridvisible=true)
        lines!(ax1, w, mag_yvals; color=line_color, linestyle=linestyle)
        lines!(ax2, w, phase; color=line_color, linestyle=linestyle)
        xlims!(ax1, first(w), last(w))
        xlims!(ax2, first(w), last(w))
        linkxaxes!(ax1, ax2)
        hidexdecorations!(ax1; grid=false, ticks=false)
        if show_title && title != ""
            Label(layout[0, 1], title; fontsize=fontsize, tellwidth=false)
        end
        return (; axes=[ax1, ax2])
    end
    _show_interactive(builder; figsize=(round(Int, 8 * 96),
                                       round(Int, 6 * 96)),
                      fig_name=title == "" ? "bode" : title)
    return nothing
end

end
