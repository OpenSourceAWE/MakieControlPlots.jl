using MakieControlPlots

X = 0:0.1:2pi
Y = sin.(X)
p = plot(X, Y; fig="a_really_long_figure_name_for_testing_purposes", title="Simple plot")