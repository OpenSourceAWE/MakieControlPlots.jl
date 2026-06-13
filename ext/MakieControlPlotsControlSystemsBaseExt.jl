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
end

function _frequency_response(sys; from=-1, to=2)
    w = exp10.(LinRange(from, to, 1000))
    mag, phase, w1 = bode(sys, w)
    return w, mag[:], phase[:]
end

_todb(mag) = 20 * log10(mag)

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
    return function(layout)
        ax1 = Axis(layout[1, 1]; xscale=log10, yscale=mag_yscale,
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
        ax2 = Axis(layout[2, 1]; xscale=log10, xlabel=xlabel,
                   ylabel="Phase [deg]", xlabelsize=bp.fontsize,
                   ylabelsize=bp.fontsize, xgridvisible=true,
                   ygridvisible=true, xminorgridvisible=true,
                   xminorticksvisible=true,
                   xminorticks=IntervalsBetween(9))
        lines!(ax1, w, mag_yvals; color=line_color, linestyle=bp.linestyle)
        lines!(ax2, w, phase; color=line_color, linestyle=bp.linestyle)
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
                   output_folder="output", disp=false, new_screen=true)
    bp = BodePlot(sys, title, from, to, db, hz, bw, linestyle, show_title,
                  fontsize, fig)
    disp && _bode_show(bp; output_folder, new_screen)
    return bp
end

function Base.display(bp::BodePlot; new_screen=true)
    _bode_show(bp; new_screen)
    return nothing
end

end
