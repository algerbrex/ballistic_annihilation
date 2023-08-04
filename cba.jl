import Distributions: Distribution, DiscreteNonParametric, Poisson, Uniform, Geometric
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
    lives::Vector{UInt32}
end

@inline
function sort_small_list(lst::Vector{Int64})::Vector{Int64}
    return lst[2] < lst[1] ? [lst[2], lst[1]] : lst
end

@inline
function resolve_collision(ps::ParticleSystem, idx1, idx2)::Union{Tuple{Int64, Int64}, Tuple{Int64}}
    if ps.lives[idx1] == ps.lives[idx2]
        return (idx1, idx2)
    elseif ps.lives[idx1] > ps.lives[idx2]
        if ps.velocities[idx1] != BLOCKADE_VEL ps.positions[idx1] = ps.positions[idx2] end
        ps.lives[idx1] -= ps.lives[idx2]
        return (idx2,)
    else
        if ps.velocities[idx2] != BLOCKADE_VEL ps.positions[idx2] = ps.positions[idx1] end
        ps.lives[idx2] -= ps.lives[idx1]
        return (idx1,)
    end
end

function make_particle_system(pos_bound, num_particles, prob_blockade, arrow_lives_dist::Distribution, blockade_lives_dist::Distribution)
    positions = sort(rand(Uniform(-pos_bound, pos_bound), num_particles))
    vel_weights = Weights([prob_blockade, (1 - prob_blockade) / 2, (1 - prob_blockade) / 2])
    velocities = sample([BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL], vel_weights, num_particles)
    lives = [velocities[i] == BLOCKADE_VEL ? rand(blockade_lives_dist) : rand(arrow_lives_dist) for i = 1:num_particles]
    return ParticleSystem(positions, velocities, lives)
end

function resolve_arrow_arrow_collisions(ps::ParticleSystem)
    matches = eachmatch(r"\>\<", string(ps.velocities...))
    indexes = []
    for match in matches
        push!(indexes, resolve_collision(ps, match.offset, match.offset + 1)...)
    end
    deleteat!(ps.positions, indexes)
    deleteat!(ps.velocities, indexes)
    deleteat!(ps.lives, indexes)
end

function resolve_arrow_blockade_collisions(ps::ParticleSystem)
    matches = findall(r"(\>\*+\<)|(\>\*+\>)|(\<\*+\<)", *(ps.velocities...))
    indexes = []

    for group in matches
        head, tail = first(group), last(group)
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

        push!(indexes, resolve_collision(ps, sort_small_list([arrow_idx, blockade_idx])...)...)
    end

    deleteat!(ps.positions, indexes)
    deleteat!(ps.velocities, indexes)
    deleteat!(ps.lives, indexes)
end

function resolve_collisions(ps::ParticleSystem)
    resolve_arrow_arrow_collisions(ps)
    resolve_arrow_blockade_collisions(ps)
end

function print_particle_counts(ps::ParticleSystem, pos_bound)
    third = pos_bound / 3
    println("<: ", sum([1 for p in zip(ps.velocities, ps.positions) if p[1] == LEFT_VEL && -third < p[2] < third]))
    println(">: ", sum([1 for p in zip(ps.velocities, ps.positions) if p[1] == RIGHT_VEL && -third < p[2] < third]))
    println("*: ", sum([1 for p in zip(ps.velocities, ps.positions) if p[1] == BLOCKADE_VEL && -third < p[2] < third]))
end

function simulate(;steps=1, pos_bound=1_000, num_particles=100, p=0.25, 
    arrow_lives_dist::Distribution, blockade_lives_dist::Distribution)

    ps = make_particle_system(pos_bound, num_particles, p, arrow_lives_dist, blockade_lives_dist)
    println("Before:")
    print_particle_counts(ps, pos_bound)

    for _ = 1:steps
        resolve_collisions(ps)
    end

    println("\nAfter ", steps, " time step(s):")
    print_particle_counts(ps, pos_bound)
end

simulate(
    steps=500,
    pos_bound=50_000,
    num_particles=1_000_000,
    p=.3,
    arrow_lives_dist=Geometric(0.5),
    blockade_lives_dist=Geometric(0.5)
)
