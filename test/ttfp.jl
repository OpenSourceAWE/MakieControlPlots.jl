#!/usr/bin/env julia

# run this using:
# time ./ttfp.jl

import Pkg; Pkg.activate(@__DIR__)

using MakieControlPlots
p = plot(rand(3))
display(p)

## Julia 1.12 ##
# on desktop: 5.32s
# on laptop: 7.5s