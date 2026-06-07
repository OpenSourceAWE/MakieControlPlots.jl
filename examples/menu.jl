using Pkg
if ! ("ControlSystemsBase" ∈ keys(Pkg.project().dependencies))
     Pkg.activate("examples")
end
using ControlSystemsBase
using MakieControlPlots
using REPL.TerminalMenus

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
    active = true
    while active
        isdefined(Main, :Revise) && Main.Revise.revise()
        menu = RadioMenu(options, pagesize=8)
        choice = request("\nType q to quit. Choose function to execute: ", menu)

        if choice != -1 && choice != length(options)
            result = eval(Meta.parse(options[choice]))
            result === nothing || display(result)
        else
            println("Left menu. Press <ctrl><d> to quit Julia!")
            active = false
        end
    end
end

example_menu()