using MakieControlPlots
x   = 1.5*ones(11)
y   = 1:0.1:2
out = min.(x,y)
p = plot(1:11, [x,y,out]; ylabel="gain", xlabel="time", labels=["input_a", "input_b", "output"], fig="2-in-one")
