using Pkg
if ! ("ControlSystemsBase" ∈ keys(Pkg.project().dependencies))
     Pkg.activate("examples")
end
using ControlSystemsBase
using MakieControlPlots
using REPL.TerminalMenus

p = nothing

options = ["basic = include(\"basic.jl\")",
           "Bode_plot = include(\"bode-plot.jl\")",
           "dual_one_axis_error_bars = include(\"dual_one_axis_error_bars.jl\")",
           "dual_one_axis = include(\"dual_one_axis.jl\")",
           "dual_y_axis_3 = include(\"dual_y-axis-3.jl\")",
           "LaTeX = include(\"latex.jl\")",
           "multi_channel_shifted = include(\"multi-channel_shifted.jl\")",
           "multi_channel_ysize = include(\"multi-channel_ysize.jl\")",
           "multi_channel_dual = include(\"multi-channel-dual.jl\")",
           "multi_channel_many = include(\"multi-channel-many.jl\")",
           "multi_channel = include(\"multi-channel.jl\")",
           "plot2d_seg = include(\"plot2d-seg.jl\")",
           "plot_2d = include(\"plot2d.jl\")",
           "plot_xy = include(\"plotxy.jl\")",
           "shifted = include(\"shifted.jl\")",
           "simple = include(\"simple.jl\")",
           "quit"]

function example_menu()
    global p
    active = true
    while active
        menu = RadioMenu(options, pagesize=8)
        choice = request("\nChoose function to execute or `q` to quit: ", menu)

        if choice != -1 && choice != length(options)
            eval(Meta.parse(options[choice]))
            if !isnothing(p)
                display(p)
                p=nothing
            end
        else
            println("Left menu. Press <ctrl><d> to quit Julia!")
            active = false
        end
    end
end

example_menu()