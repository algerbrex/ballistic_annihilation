import Distributions: Uniform
import StatsBase: sample, Weights

const FRAMES                  = 500
const RANGE_LOWER_BOUND       = -10000
const RANGE_UPPER_BOUND       = 10000
const NUM_OF_PARTICLES        = 15000
const PROBABILITY_OF_BLOCKADE = 0.3

const LEFT_VEL                = 0
const RIGHT_VEL               = 1
const BLOCKADE_VEL            = 2

VELOCITIES = [BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL]
WEIGHTS    = [PROBABILITY_OF_BLOCKADE, (1 - PROBABILITY_OF_BLOCKADE) / 2, (1 - PROBABILITY_OF_BLOCKADE) / 2]

positions = sort(rand(Uniform(RANGE_LOWER_BOUND, RANGE_UPPER_BOUND), NUM_OF_PARTICLES))
velocities = sample(VELOCITIES, Weights(WEIGHTS), NUM_OF_PARTICLES)

println("Number of left moving particles at start: ", sum(velocities .== LEFT_VEL))
println("Number of right moving particles at start: ", sum(velocities .== RIGHT_VEL))
println("Number of blockade particles at start: ", sum(velocities .== BLOCKADE_VEL))

time_steps = 0

for _ = 1:FRAMES
    num_left = length(positions)

    if num_left < 2
        continue
    end

    indexes_to_delete = Set()

    if velocities[1] == RIGHT_VEL && velocities[2] == LEFT_VEL
        push!(indexes_to_delete, 1)
        push!(indexes_to_delete, 2)
    elseif velocities[num_left] == LEFT_VEL && velocities[num_left - 1] == RIGHT_VEL
        push!(indexes_to_delete, num_left)
        push!(indexes_to_delete, num_left - 1)
    end

    if num_left == 2
        indexes = sort(collect(indexes_to_delete))
        deleteat!(positions, indexes)
        deleteat!(velocities, indexes)
        continue
    end

    for i = 2:num_left - 1
        if in(i, indexes_to_delete)
            continue
        end

        if velocities[i] == RIGHT_VEL && velocities[i + 1] == LEFT_VEL
            push!(indexes_to_delete, i)
            push!(indexes_to_delete, i + 1)
        elseif velocities[i] == LEFT_VEL && velocities[i - 1] == RIGHT_VEL
            push!(indexes_to_delete, i)
            push!(indexes_to_delete, i - 1)
        elseif velocities[i] == BLOCKADE_VEL
            if velocities[i - 1] == RIGHT_VEL && velocities[i + 1] == LEFT_VEL
                if abs(positions[i - 1] - positions[i]) < abs(positions[i + 1] - positions[i])
                    push!(indexes_to_delete, i)
                    push!(indexes_to_delete, i - 1)
                else
                    push!(indexes_to_delete, i)
                    push!(indexes_to_delete, i + 1)
                end
            elseif velocities[i - 1] == RIGHT_VEL
                push!(indexes_to_delete, i)
                push!(indexes_to_delete, i - 1)
            elseif velocities[i + 1] == LEFT_VEL
                push!(indexes_to_delete, i)
                push!(indexes_to_delete, i + 1)
            end
        end
    end

    indexes = collect(indexes_to_delete)
    sort!(indexes)

    deleteat!(positions, indexes)
    deleteat!(velocities, indexes)
end
        
println("\nNumber of left moving particles at end: ", sum(velocities .== LEFT_VEL))
println("Number of right moving particles at end: ", sum(velocities .== RIGHT_VEL))
println("Number of blockade particles at end: ", sum(velocities .== BLOCKADE_VEL))
