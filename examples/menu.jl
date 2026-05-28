using REPL.TerminalMenus: RadioMenu, request

options = ["simple = include(\"simple.jl\")",
           "basic = include(\"basic.jl\")",
           "shifted = include(\"shifted.jl\")",
           "latex = include(\"latex.jl\")",
           "plotxy = include(\"plotxy.jl\")",
           "two_in_one = include(\"two_in_one.jl\")",
           "dual_one_axis = include(\"dual_one_axis.jl\")",
           "dual_one_axis_error_bars = include(\"dual_one_axis_error_bars.jl\")",
           "dual_y_axis = include(\"dual_y-axis.jl\")",
           "dual_y_axis_3 = include(\"dual_y-axis-3.jl\")",
           "multi_channel = include(\"multi-channel.jl\")",
           "multi_channel_dual = include(\"multi-channel-dual.jl\")",
           "multi_channel_many = include(\"multi-channel-many.jl\")",
           "multi_channel_shifted = include(\"multi-channel_shifted.jl\")",
           "multi_channel_ysize = include(\"multi-channel_ysize.jl\")",
           "plot2d = include(\"plot2d.jl\")",
           "plot2d_seg = include(\"plot2d-seg.jl\")",
           "bode_plot = include(\"bode-plot.jl\")",
           "quit"]

function example_menu(options)
    active = true
    while active
        menu = RadioMenu(options, pagesize=12)
        choice = request("\nChoose example to run or `q` to quit: ", menu)

        if choice != -1 && choice != length(options)
            eval(Meta.parse(options[choice]))
        else
            println("Left menu. Press <ctrl><d> to quit Julia!")
            active = false
        end
    end
end

example_menu(options)
