using Test
using MakieControlPlots
using MakieControlPlots: PlotX

X = collect(0.0:0.1:1.0)
Y = X .^ 2

@testset "MakieControlPlots" begin
    @testset "plot(X, Y)" begin
        p = plot(X, Y; xlabel="x", ylabel="y")
        @test p isa PlotX
        @test p.X === X
        @test p.Y === Y
        @test p.xlabel == "x"
        @test p.ylabels == "y"
        @test p.type == 1
    end

    @testset "plot(Y)" begin
        p = plot(Y; xlabel="x", ylabel="y")
        @test p isa PlotX
        @test p.type == 1
        @test length(p.X) == length(Y)
    end

    @testset "plot(X, Ys) multi" begin
        p = plot(X, [Y, 2 .* Y]; labels=["a", "b"])
        @test p isa PlotX
        @test p.type == 4
        @test p.labels == ["a", "b"]
    end

    @testset "plot(X, Ys) errorbars" begin
        Yerr = 0.1 .* ones(length(Y))
        p = plot(X, [(Y, Yerr)]; labels=["a"])
        @test p isa PlotX
        @test p.type == 4
    end

    @testset "plot(X, Y1, Y2) twin-y" begin
        p = plot(X, Y, 2 .* Y; ylabels=["a", "b"])
        @test p isa PlotX
        @test p.type == 5
    end

    @testset "plot(X, [Y1, Y2], Y3) multi-left twin-y" begin
        p = plot(X, [Y, 2 .* Y], 3 .* Y;
                 ylabels=["a", "b"], labels=["a1", "a2", "b"])
        @test p isa PlotX
        @test p.type == 5
    end

    @testset "plotx" begin
        p = plotx(X, Y, 2 .* Y; ylabels=["a", "b"])
        @test p isa PlotX
        @test p.type == 2
        @test p.yzoom == 1.0
    end

    @testset "plotxy" begin
        p = plotxy(X, Y)
        @test p isa PlotX
        @test p.type == 3
    end

    @testset "save/load round-trip" begin
        p = plot(X, Y; xlabel="x", ylabel="y")
        mktempdir() do dir
            file = joinpath(dir, "p.jld2")
            MakieControlPlots.save(file, p)
            p2 = MakieControlPlots.load(file)
            @test p2.xlabel == p.xlabel
            @test p2.ylabels == p.ylabels
            @test p2.type == p.type
        end
    end

    @testset "headless export" begin
        import CairoMakie
        import Makie: Figure
        CairoMakie.activate!()
        Base.display(::Figure) = nothing
        import MakieControlPlots: _export_figure, _LAST_BUILDER

        cases = [
            () -> plot(X, Y; xlabel="x", ylabel="y", disp=true),
            () -> plot(X, [Y, 2 .* Y]; labels=["a","b"], disp=true),
            () -> plot(X, Y, 2 .* Y;
                       ylabels=["a","b"], labels=["a","b"], disp=true),
            () -> plot(X, [Y, 2 .* Y], 3 .* Y;
                       ylabels=["a","b"], labels=["a1","a2","b"],
                       disp=true),
            () -> plotx(X, Y, 2 .* Y; ylabels=["a","b"], disp=true),
            () -> plotxy(Y, X; xlabel="X", ylabel="Y", disp=true),
        ]
        mktempdir() do dir
            for (i, mk) in enumerate(cases)
                mk()
                png = joinpath(dir, "case$(i).png")
                _export_figure(png, _LAST_BUILDER[])
                @test isfile(png)
                @test filesize(png) > 1024
            end
            plot2d([[1.0,0.0,0.0],[2.0,0.0,0.0]], 0.0;
                   segments=1, fig="p2d")
            plot2d([[1.0,0.0,0.0],[2.5,0.0,0.5]], 0.5;
                   segments=1, fig="p2d")
            png = joinpath(dir, "p2d.png")
            _export_figure(png, _LAST_BUILDER[])
            @test isfile(png)
            @test filesize(png) > 1024
        end
    end

    @testset "bode_plot extension" begin
        import ControlSystemsBase
        import CairoMakie
        import Makie: Figure
        CairoMakie.activate!()
        Base.display(::Figure) = nothing
        import MakieControlPlots: _export_figure, _LAST_BUILDER

        sys = ControlSystemsBase.tf([1.0], [1.0, 1.0])
        bp = MakieControlPlots.bode_plot(sys; from=-2, to=2, title="lpf")
        @test bp.fig == ""
        MakieControlPlots.bode_plot(sys; from=-2, to=2, title="lpf", disp=true)
        mktempdir() do dir
            png = joinpath(dir, "bode.png")
            _export_figure(png, _LAST_BUILDER[])
            @test isfile(png)
            @test filesize(png) > 1024
        end
    end
end
