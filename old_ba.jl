import Distributions: Uniform
import StatsBase: sample, Weights

const LEFT_VEL::Char      = '<'
const RIGHT_VEL::Char     = '>'
const BLOCKADE_VEL::Char  = '*'

const CONSTANT::Int8            = 0
const OPP_ARROW_TO::Int8        = -2
const OPP_ARROW_AWAY::Int8      = 2
const ARROW_BLOCKADE_TO::Int8   = -1
const ARROW_BLOCKADE_AWAY::Int8 = 1

const RIGHT_ARROW_LIVES::UInt8  = 1
const LEFT_ARROW_LIVES::UInt8   = 2
const ARROW_SURVIVES::UInt8     = 3
const BLOCKADE_LIVES::UInt8     = 4
const MUTAL_ANNIHILATION::UInt8 = 5

COLLISION_TYPE_MAP = Dict(
    (RIGHT_VEL, RIGHT_VEL) => CONSTANT,
    (RIGHT_VEL, LEFT_VEL) => OPP_ARROW_TO,
    (RIGHT_VEL, BLOCKADE_VEL) => ARROW_BLOCKADE_TO,

    (LEFT_VEL, LEFT_VEL) => CONSTANT,
    (LEFT_VEL, RIGHT_VEL) => OPP_ARROW_AWAY,
    (LEFT_VEL, BLOCKADE_VEL) => ARROW_BLOCKADE_AWAY,

    (BLOCKADE_VEL, BLOCKADE_VEL) => CONSTANT,
    (BLOCKADE_VEL, LEFT_VEL) => ARROW_BLOCKADE_TO,
    (BLOCKADE_VEL, RIGHT_VEL) => ARROW_BLOCKADE_AWAY,
)


mutable struct ParticleSystem
    distances::Vector{Float64}
    distance_types::Vector{Int8}
    velocities::Vector{Char}
end


function make_particle_system(max_dist, num_particles, prob_blockade)
    vel_weights = Weights([prob_blockade, (1 - prob_blockade) / 2, (1 - prob_blockade) / 2])
    velocities = sample([BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL], vel_weights, num_particles)

    distances = sort(rand(Uniform(0, max_dist), num_particles - 1))
    distance_types = zeros(Int8, num_particles - 1)

    for i = 1: (num_particles - 1)
        collision_type = (velocities[i], velocities[i + 1])
        distance_types[i] = COLLISION_TYPE_MAP[collision_type]
    end

    return ParticleSystem(distances, distance_types, velocities)
end


function get_smallest_dist_idx(ps)
    min_idx = -1
    min_dist = Inf

    for (idx, dist) in enumerate(ps.distances)
        distance_type = ps.distance_types[idx]
        if dist < min_dist && (distance_type == OPP_ARROW_TO || distance_type == ARROW_BLOCKADE_TO)
            min_dist = dist
            min_idx = idx
        end
    end

    return min_idx
end


function resolve_nearest_collision(ps, arrow_arrow_outcomes, arrow_blockade_outcomes)
    min_dist_idx = get_smallest_dist_idx(ps)
    distance = ps.distances[min_dist_idx]
    distance_type = ps.distance_types[min_dist_idx]

    if distance_type == OPP_ARROW_TO

    elseif distance_type == ARROW_BLOCKADE_TO
        error("Non collision distance type")
    else
        error("Non collision distance type")
    end
    
    # Update distance type after deletion
    
    # Update distances

    ps.distances += (distance * ps.distance_types)
end


function print_particle_counts(ps::ParticleSystem)
    println(ps.velocities)
    println("<: ", sum([1 for v in ps.velocities if v == LEFT_VEL]))
    println(">: ", sum([1 for v in ps.velocities if v == RIGHT_VEL]))
    println("*: ", sum([1 for v in ps.velocities if v == BLOCKADE_VEL]))
end


function simulate(;steps=1, max_dist=10_000, num_particles=15, p=0.00, a=0, b=0, α=0, β=0)
    ps = make_particle_system(max_dist, num_particles, p)

    println("Before:")
    print_particle_counts(ps)

    arrow_arrow_outcomes = sample(
        [RIGHT_ARROW_LIVES, LEFT_ARROW_LIVES, BLOCKADE_GENERATED, MUTAL_ANNIHILATION], 
        Weights([a / 2, a / 2, b, 1 - (a + b)]), 
        num_particles
    )

    arrow_blockade_outcomes = sample(
        [ARROW_SURVIVES, BLOCKADE_LIVES, MUTAL_ANNIHILATION], 
        Weights([α, β, 1 - (α + β)]),
        num_particles
    )

    for _ = 1:steps
        resolve_nearest_collision(ps, arrow_arrow_outcomes, arrow_blockade_outcomes)
    end

    println("\nAfter ", steps, " step(s):")
    print_particle_counts(ps)
end


simulate()
