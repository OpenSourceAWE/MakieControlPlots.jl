using MakieControlPlots

X = 0:0.1:2pi
Y = sin.(X)

# Create an interactive plot window
p1 = plot(X, Y; fig="wait-example", title="Close window to continue")
display(p1)

p2 = plot(X, Y; fig="wait-example2", title="Close window to continue")
display(p2)

# Wait for the user to close the figure window before continuing
wait_for_figure()

println("Figure was closed. Continuing execution...")
