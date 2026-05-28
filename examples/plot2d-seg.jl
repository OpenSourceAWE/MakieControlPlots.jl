using MakieControlPlots
using MakieControlPlots: plt

# Initial position parameters
x0 = -1.0    # horizontal position
y0 = 0.0     # height from ground
ω = 2π       # angular frequency for jumping motion
SAVE = false # save each frame in the video folder

j = 0
for t in 0:0.05:7
    global j
    # Create jumping motion
    height = 2.0 + 0.3 * sin(ω * t)
    x = x0 + t     # Move right over time
    
    # Get head points
    size = 0.5
    head_points = [
        [x - 0.3, 0, height+0.4 + size],  # Top left
        [x + 0.3, 0, height+0.4 + size],  # Top right
        [x, 0, height+0.4],  # Bottom
    ]
    
    # Define points for stick figure
    neck = [x, 0, height + 0.4]        # Neck
    body = [x, 0, height]              # Body center
    lhand = [x - 0.3, 0, height + 0.2 * sin(ω * t)]  # Left hand
    rhand = [x + 0.3, 0, height + 0.2 * sin(ω * t)]  # Right hand
    lfoot = [x - 0.3, 0, height - 1.6 - 0.2 * cos(ω * t)]  # Left foot
    rfoot = [x + 0.3, 0, height - 1.6 + 0.2 * cos(ω * t)]  # Right foot

    # Combine all points (head points first, then body parts)
    points = [head_points..., neck, body, lhand, rhand, lfoot, rfoot]
    
    # Define segments (connections between points)
    segments = [
        [1, 2],  # Head top
        [2, 3],  # Head right
        [1, 3],  # Head left
        [3, 4],  # Connect head to neck
        [4, 5],  # Neck to body
        [5, 6],  # Body to left hand
        [5, 7],  # Body to right hand
        [5, 8],  # Body to left foot
        [5, 9]  # Body to right foot
    ]
    
    # Plot the stick figure
    plot2d(points, segments, t; zoom=false, xlim=(0, 5), ylim=(0, 5))
    if SAVE
        plt.savefig("video/"*"img-"*lpad(j, 4, "0"))
    end
    j += 1
    sleep(0.05)
end
# create .gif file:
# cd video
# rm img-000*
# convert -delay 0 -loop 0 *.png animation.gif