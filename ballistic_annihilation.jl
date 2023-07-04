using Plots
import Distributions: Uniform
import StatsBase: sample, Weights

const FRAMES                  = 200
const RANGE_LOWER_BOUND       = -3000
const RANGE_UPPER_BOUND       = 3000
const RANGE_TO_COUNT_LOWER_BOUND = RANGE_LOWER_BOUND / 1
const RANGE_TO_COUNT_UPPER_BOUND = RANGE_UPPER_BOUND / 1
const NUM_OF_PARTICLES        = 1200
const PROBABILITY_OF_BLOCKADE = 0.18


const PROBABILITY_ARROW_SURVIES         = 1/3
const PROBABILITY_BLOCKADE_SURVIVES     = 1/3
const PROBABILITY_OF_MUTAL_ANNIHILATION = 1 - (PROBABILITY_ARROW_SURVIES + PROBABILITY_BLOCKADE_SURVIVES)
const ALPHA                             = 1/3

const LEFT_VEL                = 0
const RIGHT_VEL               = 1
const BLOCKADE_VEL            = 2

VELOCITIES            = [BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL]
ASSIGNMENT_WEIGHTS = Weights([
    PROBABILITY_OF_BLOCKADE, 
    (1 - PROBABILITY_OF_BLOCKADE) / 2, 
    (1 - PROBABILITY_OF_BLOCKADE) / 2
])

BLOCKADE_ARROW_COLLISION_WEIGHTS = Weights([
    PROBABILITY_OF_MUTAL_ANNIHILATION, 
    PROBABILITY_BLOCKADE_SURVIVES,
    PROBABILITY_ARROW_SURVIES
])

ARROW_ARROW_COLLISION_WEIGHTS = Weights([
    ALPHA / 2, # Right arrow survives
    ALPHA / 2, # Left arrow survives
    1 - ALPHA  # Both arrows are annihilated
])

# To get the diagram to show remeber to run "julia" from the command
# line to enter into the REPl, and then run "include(path/to/script.jl)"
# to run the script.

function run_simulation() 
    positions = sort(rand(Uniform(RANGE_LOWER_BOUND, RANGE_UPPER_BOUND), NUM_OF_PARTICLES))
    velocities = sample(VELOCITIES, ASSIGNMENT_WEIGHTS, NUM_OF_PARTICLES)

    time_steps_lived = Dict()
    max_dist_traveled = 0

    for (pos, vel) in zip(positions, velocities)
        if RANGE_TO_COUNT_LOWER_BOUND < pos < RANGE_TO_COUNT_UPPER_BOUND
            time_steps_lived[pos] = [vel, 0.0]
        end
    end

    particle_counts = Dict(LEFT_VEL => 0, RIGHT_VEL => 0, BLOCKADE_VEL => 0)
    for (pos, vel) in zip(positions, velocities)
        if RANGE_TO_COUNT_LOWER_BOUND < pos < RANGE_TO_COUNT_UPPER_BOUND
            particle_counts[vel] += 1
        end
    end

    println("Number of left moving particles at start in middle third: ", particle_counts[LEFT_VEL])
    println("Number of right moving particles at start in middle third: ", particle_counts[RIGHT_VEL])
    println("Number of blockade particles at start in middle third: ", particle_counts[BLOCKADE_VEL])

    for _ = 1:FRAMES
        num_left = length(positions)
        indexes_to_delete = []

        i = 1
        while i <= num_left
            dist = 0
            indexes_to_update = []
            
            if i + 1 <= num_left && velocities[i] == RIGHT_VEL && velocities[i + 1] == LEFT_VEL
                dist = (positions[i + 1] - positions[i]) / 2
                indexes_to_update = sample([[i + 1], [i], [i, i + 1]], ARROW_ARROW_COLLISION_WEIGHTS)
                push!(indexes_to_delete, indexes_to_update...)
                i += 1
            elseif i - 1 >= 1 && velocities[i] == LEFT_VEL && velocities[i - 1] == RIGHT_VEL
                dist = (positions[i] - positions[i - 1]) / 2
                indexes_to_update = sample([[i], [i - 1], [i - 1, i]], ARROW_ARROW_COLLISION_WEIGHTS)
                push!(indexes_to_delete, indexes_to_update...)
            elseif velocities[i] == BLOCKADE_VEL
                if i + 1 <= num_left && i - 1 >= 1 && velocities[i - 1] == RIGHT_VEL && velocities[i + 1] == LEFT_VEL
                    if abs(positions[i - 1] - positions[i]) < abs(positions[i + 1] - positions[i])
                        dist = positions[i] - positions[i - 1]
                        indexes_to_update = sample([[i - 1, i], [i - 1], [i]], BLOCKADE_ARROW_COLLISION_WEIGHTS)
                        push!(indexes_to_delete, indexes_to_update...)
                    else
                        dist = positions[i + 1] - positions[i]
                        indexes_to_update = sample([[i, i + 1], [i + 1], [i]], BLOCKADE_ARROW_COLLISION_WEIGHTS)
                        push!(indexes_to_delete, indexes_to_update...)
                        i += 1
                    end
                elseif i - 1 >= 1 && velocities[i - 1] == RIGHT_VEL
                    dist = positions[i] - positions[i - 1]
                    indexes_to_update = sample([[i - 1, i], [i - 1], [i]], BLOCKADE_ARROW_COLLISION_WEIGHTS)
                    push!(indexes_to_delete, indexes_to_update...)
                elseif i + 1 <= num_left && velocities[i + 1] == LEFT_VEL
                    dist = positions[i + 1] - positions[i]
                    indexes_to_update = sample([[i, i + 1], [i + 1], [i]], BLOCKADE_ARROW_COLLISION_WEIGHTS)
                    push!(indexes_to_delete, indexes_to_update...)
                    i += 1
                end
            end

            i += 1

            for idx in indexes_to_update
                pos = positions[idx]
                if RANGE_TO_COUNT_LOWER_BOUND < pos < RANGE_TO_COUNT_UPPER_BOUND
                    time_steps_lived[pos][2] = dist
                    max_dist_traveled = max(dist, max_dist_traveled)
                end
            end

        end

        for (pos, vel) in zip(positions, velocities)
            if RANGE_TO_COUNT_LOWER_BOUND < pos < RANGE_TO_COUNT_UPPER_BOUND
                particle_counts[vel] += 1
            end
        end

        deleteat!(positions, indexes_to_delete)
        deleteat!(velocities, indexes_to_delete)
    end

    for pos in positions
        if RANGE_TO_COUNT_LOWER_BOUND < pos < RANGE_TO_COUNT_UPPER_BOUND
            time_steps_lived[pos][2] = max_dist_traveled
        end
    end

    particle_counts[LEFT_VEL] = 0
    particle_counts[RIGHT_VEL] = 0
    particle_counts[BLOCKADE_VEL] = 0
            
    for (pos, vel) in zip(positions, velocities)
        if RANGE_TO_COUNT_LOWER_BOUND < pos < RANGE_TO_COUNT_UPPER_BOUND
            particle_counts[vel] += 1
        end
    end

    println("Number of left moving particles at start in middle third: ", particle_counts[LEFT_VEL])
    println("Number of right moving particles at start in middle third: ", particle_counts[RIGHT_VEL])
    println("Number of blockade particles at start in middle third: ", particle_counts[BLOCKADE_VEL])

    return time_steps_lived, max_dist_traveled
end


function create_diagram(data, max_dist_traveled)
    lines = []
    for (pos, vel_and_dist) in data
        if vel_and_dist[1] == RIGHT_VEL
            x_coords = [pos + vel_and_dist[2], pos] 
            y_coords = [vel_and_dist[2], 0.0]
        elseif vel_and_dist[1] == LEFT_VEL
            x_coords = [pos - vel_and_dist[2], pos] 
            y_coords = [vel_and_dist[2], 0.0]
        else
            x_coords = [pos, pos]
            y_coords = [vel_and_dist[2], 0.0]
        end
        push!(lines, (x_coords, y_coords, vel_and_dist[1]))
    end

    plt = plot(
        legend=false, 
        ylims=(0, max_dist_traveled * 3),
        xlims=(RANGE_TO_COUNT_LOWER_BOUND, RANGE_TO_COUNT_UPPER_BOUND), 
        axis=([], false)
    )

    for line in lines
        color = "Light Coral"
        if line[3] == BLOCKADE_VEL
            color = "Light Blue"
        end
        plot!(plt, line[1:2], color=color)
    end

    gui(plt)
end


data, max_dist_traveled = run_simulation()
create_diagram(data, max_dist_traveled)
