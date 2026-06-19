using PrecompileTools: @setup_workload, @compile_workload

@setup_workload begin
    X = collect(0.0:0.1:1.0)
    Y = X .^ 2
    Y2 = 2 .* Y
    Y3 = 3 .* Y
    Yerr = 0.1 .* ones(length(Y))
    pos = [[1.0, 0.0, 0.0], [2.0, 0.0, 0.0]]
    seg = [[1, 2]]

    @compile_workload begin
        plot(Y; xlabel="x", ylabel="y", disp=false)
        plot(X, Y; xlabel="x", ylabel="y", title="t", disp=false)
        plot(X, Y; scatter=true, ann=(0.5, 0.5, "a"),
             xlims=(0, 1), ylims=(0, 1), disp=false)
        plot(X, [Y, Y2]; labels=["a", "b"], disp=false)
        plot(X, [(Y, Yerr)]; labels=["a"], disp=false)
        plot(X, Y, Y2; ylabels=["a", "b"], disp=false)
        plot(X, [Y, Y2], Y3;
             ylabels=["a", "b"], labels=["a1", "a2", "b"], disp=false)
        plotx(X, Y, Y2; ylabels=["a", "b"], labels=["a", "b"], disp=false)
        plotxy(X, Y; xlabel="x", ylabel="y", disp=false)
        plotxy(X, Y; scatter=true, disp=false)

        p = plot(X, Y; xlabel="x", ylabel="y", disp=false)
        mktempdir() do dir
            file = joinpath(dir, "p.jld2")
            save(file, p)
            load(file)
        end

        CairoMakie.activate!()
        try
            fig = Figure(; size=(400, 300))
            layout = GridLayout(fig[1, 1])
            ax = Axis(layout[1, 1]; xlabel="x", ylabel="y")
            lines!(ax, X, Y)
            scatter!(ax, X, Y; color=:red, markersize=8)
            errorbars!(ax, X, Y, Yerr; whiskerwidth=10)
            text!(ax, 0.5, 0.5; text="a", fontsize=14)
            Label(layout[0, 1], "title"; fontsize=14, tellwidth=false)
            xlims!(ax, 0, 1)
            ylims!(ax, 0, 1)

            fig2 = Figure(; size=(400, 300))
            layout2 = GridLayout(fig2[1, 1])
            ax1 = Axis(layout2[1, 1]; ylabel="a", ylabelcolor=:green,
                       yticklabelcolor=:green)
            ax2 = Axis(layout2[1, 1]; ylabel="b", yaxisposition=:right,
                       ylabelcolor=:red, yticklabelcolor=:red,
                       backgroundcolor=RGBAf(0, 0, 0, 0))
            hidespines!(ax2)
            hidexdecorations!(ax2)
            linkxaxes!(ax1, ax2)
            l1 = lines!(ax1, X, Y; color=:green)
            l2 = lines!(ax2, X, Y2; color=:red)
            Legend(layout2[1, 1], [l1, l2], ["a", "b"];
                   tellwidth=false, tellheight=false,
                   halign=:left, valign=:top)
            ax_leg = Axis(layout[2, 1]; ylabel="z")
            lines!(ax_leg, X, Y; label="a")
            lines!(ax_leg, X, Y2; label="b")
            axislegend(ax_leg)

            mktempdir() do dir
                Makie.save(joinpath(dir, "p.png"), fig)
                Makie.save(joinpath(dir, "p.pdf"), fig)
                Makie.save(joinpath(dir, "p2.png"), fig2)
            end
        finally
            try
                GLMakie.activate!()
            catch
            end
        end
    end
end
