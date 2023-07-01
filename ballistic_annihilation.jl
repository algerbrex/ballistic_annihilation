import Distributions: Uniform
import StatsBase: sample, Weights

const FRAMES                  = 500
const RANGE_LOWER_BOUND       = -10000
const RANGE_UPPER_BOUND       = 10000
const NUM_OF_PARTICLES        = 1_000_000
const PROBABILITY_OF_BLOCKADE = 0.24

const LEFT_VEL                = 0
const RIGHT_VEL               = 1
const BLOCKADE_VEL            = 2

VELOCITIES = [BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL]
WEIGHTS    = [PROBABILITY_OF_BLOCKADE, (1 - PROBABILITY_OF_BLOCKADE) / 2, (1 - PROBABILITY_OF_BLOCKADE) / 2]


function run_simulation() 
    positions = sort(rand(Uniform(RANGE_LOWER_BOUND, RANGE_UPPER_BOUND), NUM_OF_PARTICLES))
    velocities = sample(VELOCITIES, Weights(WEIGHTS), NUM_OF_PARTICLES)

    println("Number of left moving particles at start: ", sum(velocities .== LEFT_VEL))
    println("Number of right moving particles at start: ", sum(velocities .== RIGHT_VEL))
    println("Number of blockade particles at start: ", sum(velocities .== BLOCKADE_VEL))

    for _ = 1:FRAMES
        num_left = length(positions)

        if num_left <= 2
            if velocities[1] != velocities[2]
                # This is not technically correct to do, since a left moving arrow at 1
                # would never collide with a right moving arrow at 2 in the simulation, but 
                # on the infinite line these arrows would die as time tended towards infinity.
                # Additionally this also simplifies the code.
                positions = []
                velocities = []
            end
            break
        end

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
                        push!(indexes_to_delete, i - 1, i)
                    else
                        push!(indexes_to_delete, i, i + 1)
                        i += 1
                    end
                elseif i - 1 >= 1 && velocities[i - 1] == RIGHT_VEL
                    push!(indexes_to_delete, i - 1, i)
                elseif i + 1 <= num_left && velocities[i + 1] == LEFT_VEL
                    push!(indexes_to_delete, i, i + 1)
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
