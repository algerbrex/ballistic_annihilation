import Distributions: Uniform
import StatsBase: sample, Weights

const FRAMES                  = 500
const RANGE_LOWER_BOUND       = -30000
const RANGE_UPPER_BOUND       = 30000
const NUM_OF_PARTICLES        = 3_000_000
const PROBABILITY_OF_BLOCKADE = 0.75

const A                       = 9/10
const B                       = 0
const C                       = 1 - (A + B)

const LEFT_VEL                = 0
const RIGHT_VEL               = 1
const BLOCKADE_VEL            = 2

VELOCITIES            = [BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL]
ASSIGNMENT_WEIGHTS    = Weights([PROBABILITY_OF_BLOCKADE, (1 - PROBABILITY_OF_BLOCKADE) / 2, (1 - PROBABILITY_OF_BLOCKADE) / 2])
COLLISION_WEIGHTS     = Weights([C, B, A])


function run_simulation() 
    positions = sort(rand(Uniform(RANGE_LOWER_BOUND, RANGE_UPPER_BOUND), NUM_OF_PARTICLES))
    velocities = sample(VELOCITIES, ASSIGNMENT_WEIGHTS, NUM_OF_PARTICLES)

    println("Number of left moving particles at start: ", sum(velocities .== LEFT_VEL))
    println("Number of right moving particles at start: ", sum(velocities .== RIGHT_VEL))
    println("Number of blockade particles at start: ", sum(velocities .== BLOCKADE_VEL))

    for _ = 1:FRAMES
        num_left = length(positions)
        indexes_to_delete = []
        i = 1
        
        while i <= num_left
            if i + 1 <= num_left && velocities[i] == RIGHT_VEL && velocities[i + 1] == LEFT_VEL
                push!(indexes_to_delete, i, i + 1)
                i += 1
            elseif i - 1 >= 1 && velocities[i] == LEFT_VEL && velocities[i - 1] == RIGHT_VEL
                push!(indexes_to_delete, i, i - 1)
            elseif velocities[i] == BLOCKADE_VEL
                if i + 1 <= num_left && i - 1 >= 1 && velocities[i - 1] == RIGHT_VEL && velocities[i + 1] == LEFT_VEL
                    if abs(positions[i - 1] - positions[i]) < abs(positions[i + 1] - positions[i])
                        collision_result = sample([[i - 1, i], [i - 1], [i]], COLLISION_WEIGHTS)
                        push!(indexes_to_delete, collision_result...)
                    else
                        collision_result = sample([[i, i + 1], [i + 1], [i]], COLLISION_WEIGHTS)
                        push!(indexes_to_delete, collision_result...)
                        i += 1
                    end
                elseif i - 1 >= 1 && velocities[i - 1] == RIGHT_VEL
                    collision_result = sample([[i - 1, i], [i - 1], [i]], COLLISION_WEIGHTS)
                    push!(indexes_to_delete, collision_result...)
                elseif i + 1 <= num_left && velocities[i + 1] == LEFT_VEL
                    collision_result = sample([[i, i + 1], [i + 1], [i]], COLLISION_WEIGHTS)
                    push!(indexes_to_delete, collision_result...)
                    i += 1
                end
            end
            i += 1
        end

        deleteat!(positions, indexes_to_delete)
        deleteat!(velocities, indexes_to_delete)
    end
            
    println("\nNumber of left moving particles at end: ", sum(velocities .== LEFT_VEL))
    println("Number of right moving particles at end: ", sum(velocities .== RIGHT_VEL))
    println("Number of blockade particles at end: ", sum(velocities .== BLOCKADE_VEL))
end


run_simulation()
