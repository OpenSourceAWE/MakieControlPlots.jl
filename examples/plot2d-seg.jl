using MakieControlPlots

x0 = -1.0
y0 = 0.0
ω = 2π

for t in 0:0.05:7
    height = 2.0 + 0.3 * sin(ω * t)
    x = x0 + t

    size = 0.5
    head_points = [
        [x - 0.3, 0, height+0.4 + size],
        [x + 0.3, 0, height+0.4 + size],
        [x, 0, height+0.4],
    ]

    neck = [x, 0, height + 0.4]
    body = [x, 0, height]
    lhand = [x - 0.3, 0, height + 0.2 * sin(ω * t)]
    rhand = [x + 0.3, 0, height + 0.2 * sin(ω * t)]
    lfoot = [x - 0.3, 0, height - 1.6 - 0.2 * cos(ω * t)]
    rfoot = [x + 0.3, 0, height - 1.6 + 0.2 * cos(ω * t)]

    points = [head_points..., neck, body, lhand, rhand, lfoot, rfoot]

    segments = [
        [1, 2],
        [2, 3],
        [1, 3],
        [3, 4],
        [4, 5],
        [5, 6],
        [5, 7],
        [5, 8],
        [5, 9]
    ]

    plot2d(points, segments, t; zoom=false, xlim=(0, 5), ylim=(0, 5))
    sleep(0.05)
end
