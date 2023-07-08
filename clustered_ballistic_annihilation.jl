import Distributions: Uniform, Poisson
import StatsBase: sample, Weights

const FRAMES                     = 500
const RANGE_LOWER_BOUND          = -30000
const RANGE_UPPER_BOUND          = 30000
const RANGE_TO_COUNT_LOWER_BOUND = RANGE_LOWER_BOUND / 3
const RANGE_TO_COUNT_UPPER_BOUND = RANGE_UPPER_BOUND / 3
const NUM_OF_PARTICLES           = 5_000_000
const PROBABILITY_OF_BLOCKADE    = (1/3) - 0.01

const GEO_P_FOR_ARROWS    = 1
const GEO_P_FOR_BLOCKADES = 1

const LEFT_VEL                = 0
const RIGHT_VEL               = 1
const BLOCKADE_VEL            = 2

VELOCITIES            = [BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL]
ASSIGNMENT_WEIGHTS = Weights([
    PROBABILITY_OF_BLOCKADE, 
    (1 - PROBABILITY_OF_BLOCKADE) / 2, 
    (1 - PROBABILITY_OF_BLOCKADE) / 2
])


# Note: Geometrics supported on (0, Infinity) rather
# than (1, Infinity)
GEO_FOR_ARROWS    = Poisson(GEO_P_FOR_ARROWS)
GEO_FOR_BLOCKADES = Poisson(GEO_P_FOR_BLOCKADES) 


@inline
function resolve_collision(lives, idx1, idx2)
    if lives[idx1] == lives[idx2]
        return [idx1, idx2]
    elseif lives[idx1] > lives[idx2]
        lives[idx1] -= lives[idx2]
        return [idx2]
    else
        lives[idx2] -= lives[idx1]
        return [idx1]
    end
end


function run_simulation() 
    positions = sort(rand(Uniform(RANGE_LOWER_BOUND, RANGE_UPPER_BOUND), NUM_OF_PARTICLES))
    velocities = sample(VELOCITIES, ASSIGNMENT_WEIGHTS, NUM_OF_PARTICLES)
    lives = [velocities[i] == BLOCKADE_VEL ? rand(GEO_FOR_BLOCKADES) : rand(GEO_FOR_ARROWS) for i = 1:NUM_OF_PARTICLES]

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
            particles_dying = []
            if i + 1 <= num_left && velocities[i] == RIGHT_VEL && velocities[i + 1] == LEFT_VEL
                particles_dying = resolve_collision(lives, i, i + 1)
                i += 1
            elseif i - 1 >= 1 && velocities[i] == LEFT_VEL && velocities[i - 1] == RIGHT_VEL
                particles_dying = resolve_collision(lives, i - 1, i)
            elseif velocities[i] == BLOCKADE_VEL
                if i + 1 <= num_left && i - 1 >= 1 && velocities[i - 1] == RIGHT_VEL && velocities[i + 1] == LEFT_VEL
                    if abs(positions[i - 1] - positions[i]) < abs(positions[i + 1] - positions[i])
                        particles_dying = resolve_collision(lives, i - 1, i)
                    else
                        particles_dying = resolve_collision(lives, i, i + 1)
                        i += 1
                    end
                elseif i - 1 >= 1 && velocities[i - 1] == RIGHT_VEL
                    particles_dying = resolve_collision(lives, i - 1, i)
                elseif i + 1 <= num_left && velocities[i + 1] == LEFT_VEL
                    particles_dying = resolve_collision(lives, i, i + 1)
                    i += 1
                end
            end

            push!(indexes_to_delete, particles_dying...)
            i += 1
        end

        deleteat!(positions, indexes_to_delete)
        deleteat!(velocities, indexes_to_delete)
        deleteat!(lives, indexes_to_delete)
    end

    particle_counts[LEFT_VEL] = 0
    particle_counts[RIGHT_VEL] = 0
    particle_counts[BLOCKADE_VEL] = 0

    for (pos, vel) in zip(positions, velocities)
        if RANGE_TO_COUNT_LOWER_BOUND < pos < RANGE_TO_COUNT_UPPER_BOUND
            particle_counts[vel] += 1
        end
    end
            
    println("\nNumber of left moving particles at end in middle third: ", particle_counts[LEFT_VEL])
    println("Number of right moving particles at end in middle third: ", particle_counts[RIGHT_VEL])
    println("Number of blockade particles at end in middle third: ", particle_counts[BLOCKADE_VEL])
end


run_simulation()
