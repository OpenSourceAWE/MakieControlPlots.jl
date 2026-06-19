using Test
using MakieControlPlots
using MakieControlPlots: PlotX
using JLD2
import Makie: Figure
Base.display(::Figure) = nothing

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

    @testset "export preserves zoom" begin
        import CairoMakie, Makie
        import Makie: GridLayout, FileIO
        CairoMakie.activate!()
        import MakieControlPlots: _export_figure, _LAST_BUILDER, _extract_axes

        plot(X, Y; xlabel="x", ylabel="y", disp=true)
        builder = _LAST_BUILDER[]
        fig = Figure()
        live = _extract_axes(builder(GridLayout(fig[1, 1])))
        @test !isempty(live)
        Makie.limits!(live[1], 0.2, 0.4, 0.0, 0.1)
        mktempdir() do dir
            zoomed = joinpath(dir, "zoomed.png")
            full = joinpath(dir, "full.png")
            _export_figure(zoomed, builder, live)
            _export_figure(full, builder)
            @test isfile(zoomed) && isfile(full)
            @test FileIO.load(zoomed) != FileIO.load(full)
        end
    end

    @testset "saved size matches screen" begin
        import CairoMakie
        import Makie: FileIO
        CairoMakie.activate!()
        import MakieControlPlots: _export_figure, _LAST_BUILDER, _LAST_FIGSIZE

        plotx(X, Y, 2 .* Y, 3 .* Y, 4 .* Y, 5 .* Y;
              ylabels=["a","b","c","d","e"], disp=true)
        figsize = _LAST_FIGSIZE[]
        @test figsize[2] > figsize[1]
        mktempdir() do dir
            png = joinpath(dir, "tall.png")
            _export_figure(png, _LAST_BUILDER[]; figsize)
            img = FileIO.load(png)
            ppu = 1
            @test size(img) == (figsize[2] * ppu, figsize[1] * ppu)
        end
    end

    @testset "bode_plot extension" begin
        import ControlSystemsBase
        import CairoMakie
        CairoMakie.activate!()
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

    @testset "save/load Dict format" begin
        p = plot(X, Y; xlabel="x", ylabel="y", label="test_line",
                 xscale=:log10, grid=false, xticks=[0.1, 1.0])
        mktempdir() do dir
            file = joinpath(dir, "p.jld2")
            MakieControlPlots.save(file, p)

            # Must contain __version__
            raw = JLD2.load(file)["plot"]
            @test raw isa Dict
            @test haskey(raw, :__version__)

            # Round-trip via load()
            p2 = MakieControlPlots.load(file)
            @test p2 isa PlotX
            @test p2.xlabel == "x"
            @test p2.ylabels == "y"
            @test p2.type == 1
            @test p2.label == "test_line"
            @test p2.xscale == :log10
            @test p2.grid == false
            @test p2.xticks == [0.1, 1.0]
        end
    end

    @testset "Upgrade rconvert fills defaults" begin
        # Simulate loading a legacy struct with fewer fields via rconvert
        nt = (X=collect(0.0:0.1:1.0), Y=collect(0.0:0.1:1.0),
              labels=nothing, xlabel="x", ylabels="y", title="old",
              ysize=16, yzoom=nothing, xlims=nothing, ylims=nothing,
              ann=nothing, scatter=false, fig="", type=1, xsize=16,
              legend_position=:auto, legendsize=16, titlesize=18)
        p = JLD2.rconvert(PlotX, nt)
        @test p isa PlotX
        @test p.xlabel == "x"
        @test p.ylabels == "y"
        @test p.title == "old"
        # Fields not in legacy file get defaults
        @test p.xscale == :identity
        @test p.grid == true
        @test p.label == ""
        @test p.xticks === nothing
    end

    @testset "migrate_legacy_plotx_file" begin
        p = plot(X, Y; xlabel="legacy_x", ylabel="legacy_y",
                 title="legacy test")
        mktempdir() do dir
            legacy = joinpath(dir, "legacy.jld2")
            JLD2.save(legacy, "plot", p)

            # Migrate in-place
            result = MakieControlPlots.migrate_legacy_plotx_file(legacy)
            @test result == true

            # Now reads as Dict format
            p2 = MakieControlPlots.load(legacy)
            @test p2 isa PlotX
            @test p2.xlabel == "legacy_x"
            @test p2.ylabels == "legacy_y"
            @test p2.title == "legacy test"

            # Second call returns false (already migrated)
            result2 = MakieControlPlots.migrate_legacy_plotx_file(legacy)
            @test result2 == false
        end
    end

    @testset "migrate_legacy_plotx_file to output_path" begin
        p = plot(X, Y; xlabel="mig", ylabel="test")
        mktempdir() do dir
            legacy = joinpath(dir, "legacy.jld2")
            migrated = joinpath(dir, "migrated.jld2")
            JLD2.save(legacy, "plot", p)

            result = MakieControlPlots.migrate_legacy_plotx_file(legacy;
                                                                 output_path=migrated)
            @test result == true
            @test isfile(migrated)
            @test isfile(legacy)  # original untouched

            p2 = MakieControlPlots.load(migrated)
            @test p2.xlabel == "mig"
            @test p2.ylabels == "test"
        end
    end

    @testset "save/load round-trip all fields" begin
        p = plotx(X, Y, 2 .* Y; labels=["a", "b"],
                 ylabels=["left", "right"], title="multi test",
                 xlims=(0.0, 0.5), ylims=(0.0, 0.25),
                 legend_position=:lt, legendsize=14, titlesize=22,
                 scatter=true, xsize=20, ysize=18)
        mktempdir() do dir
            file = joinpath(dir, "p.jld2")
            MakieControlPlots.save(file, p)
            p2 = MakieControlPlots.load(file)
            @test p2.labels == ["a", "b"]
            @test p2.ylabels == ["left", "right"]
            @test p2.title == "multi test"
            @test p2.xlims == (0.0, 0.5)
            @test p2.ylims == (0.0, 0.25)
            @test p2.legend_position == :lt
            @test p2.legendsize == 14
            @test p2.titlesize == 22
            @test p2.scatter == true
            @test p2.xsize == 20
            @test p2.ysize == 18
        end
    end
end
