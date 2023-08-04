import Distributions: Uniform
import StatsBase: sample, Weights

const LEFT_VEL      = '<'
const RIGHT_VEL     = '>'
const BLOCKADE_VEL  = '*'

const RIGHT_ARROW_LIVES::UInt8  = 1
const LEFT_ARROW_LIVES::UInt8   = 2
const ARROW_SURVIVES::UInt8     = 3
const BLOCKADE_LIVES::UInt8     = 4
const MUTAL_ANNIHILATION::UInt8 = 5
const BLOCKADE_GENERATED::UInt8 = 6

mutable struct ParticleSystem
    positions::Vector{Float64}
    velocities::Vector{Char}
end

@inline
function sort_small_list(lst::Vector{Int64})::Vector{Int64}
    return lst[2] < lst[1] ? [lst[2], lst[1]] : lst
end

function make_particle_system(pos_bound, num_particles, prob_blockade)
    positions = sort(rand(Uniform(-pos_bound, pos_bound), num_particles))
    vel_weights = Weights([prob_blockade, (1 - prob_blockade) / 2, (1 - prob_blockade) / 2])
    velocities = sample([BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL], vel_weights, num_particles)
    return ParticleSystem(positions, velocities)
end

function resolve_arrow_arrow_collisions(ps::ParticleSystem, arrow_arrow_outcome::Vector{UInt8})
    matches = eachmatch(r"\>\<", string(ps.velocities...))
    indexes = []
    for match in matches
        outcome = pop!(arrow_arrow_outcome)
        right_arrow_idx, left_arrow_idx = match.offset, match.offset + 1

        if outcome == RIGHT_ARROW_LIVES
            ps.positions[right_arrow_idx] = ps.positions[left_arrow_idx]
            push!(indexes, left_arrow_idx)
        elseif outcome == LEFT_ARROW_LIVES
            ps.positions[left_arrow_idx] = ps.positions[right_arrow_idx]
            push!(indexes, right_arrow_idx)
        elseif outcome == BLOCKADE_GENERATED
            ps.positions[right_arrow_idx] = (ps.positions[left_arrow_idx] - ps.positions[right_arrow_idx]) / 2
            ps.velocities[right_arrow_idx] = BLOCKADE_VEL
            push!(indexes, left_arrow_idx)
        else
            push!(indexes, right_arrow_idx, left_arrow_idx)
        end
    end
    deleteat!(ps.positions, indexes)
    deleteat!(ps.velocities, indexes)
end

function resolve_arrow_blockade_collisions(ps::ParticleSystem, arrow_blockade_outcomes::Vector{UInt8})
    matches = findall(r"(\>\*+\<)|(\>\*+\>)|(\<\*+\<)", *(ps.velocities...))
    indexes = []

    for group in matches
        head, tail = first(group), last(group)
        outcome = pop!(arrow_blockade_outcomes)
        arrow_idx, blockade_idx = -1, -1
 
        if ps.velocities[head] == RIGHT_VEL && ps.velocities[tail] == LEFT_VEL &&  length(group) == 3
            blockade_idx = head + 1
            if ps.positions[blockade_idx] - ps.positions[head] < ps.positions[tail] - ps.positions[blockade_idx]
                arrow_idx = head
            else
                arrow_idx = tail
            end
        elseif ps.velocities[head] == RIGHT_VEL && ps.velocities[tail] == LEFT_VEL &&  length(group) > 3
            right_blockade_idx, left_blockade_idx = head + 1, tail - 1
            if ps.positions[right_blockade_idx] - ps.positions[head] < ps.positions[tail] - ps.positions[left_blockade_idx]
                blockade_idx = right_blockade_idx
                arrow_idx = head
            else
                blockade_idx = left_blockade_idx
                arrow_idx = tail
            end
        elseif ps.velocities[head] == RIGHT_VEL
            arrow_idx, blockade_idx = head, head + 1
        else
            arrow_idx, blockade_idx = tail, tail - 1
        end

        if outcome == ARROW_SURVIVES
            ps.positions[arrow_idx] = ps.positions[blockade_idx]
            push!(indexes, blockade_idx)
        elseif outcome == BLOCKADE_LIVES
            push!(indexes, arrow_idx)
        else
            push!(indexes, sort_small_list([arrow_idx, blockade_idx])...)
        end
    end

    deleteat!(ps.positions, indexes)
    deleteat!(ps.velocities, indexes)
end

function resolve_collisions(ps::ParticleSystem, arrow_arrow_outcomes::Vector{UInt8}, arrow_blockade_outcomes::Vector{UInt8})
    resolve_arrow_arrow_collisions(ps, arrow_arrow_outcomes)
    resolve_arrow_blockade_collisions(ps, arrow_blockade_outcomes)
end

function print_particle_counts(ps::ParticleSystem, pos_bound)
    third = pos_bound / 3
    println("<: ", sum([1 for p in ps.velocities if p[1] == LEFT_VEL]))
    println(">: ", sum([1 for p in ps.velocities if p[1] == RIGHT_VEL]))
    println("*: ", sum([1 for p in ps.velocities if p[1] == BLOCKADE_VEL]))
end

function simulate(;steps=1, pos_bound=1_000, num_particles=100, p=0.25, a=0, b=0, α=0, β=0)
    ps = make_particle_system(pos_bound, num_particles, p)
    println("Before:")
    print_particle_counts(ps, pos_bound)

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
        resolve_collisions(ps, arrow_arrow_outcomes, arrow_blockade_outcomes)
    end

    println("\nAfter ", steps, " time step(s):")
    print_particle_counts(ps, pos_bound)
end

simulate(
    steps=1,
    pos_bound=10_000,
    num_particles=1_000_000
)
