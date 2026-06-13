using MakieControlPlots

t = 0
x0 = 2.0
z0 = 0.0
for t in 0:0.1:5
    global x0, z0
    plot2d([[1,0,0], [x0,0,z0]], t; segments=1, labelsize=20, fig="2d plot")
    x0 += 0.1; z0 += 0.1
    sleep(0.1)
end