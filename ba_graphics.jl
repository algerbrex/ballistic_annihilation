using Plots
import Distributions: Uniform
import StatsBase: sample, Weights

const LEFT_VEL::Int8     = -1
const RIGHT_VEL::Int8    =  1
const BLOCKADE_VEL::Int8 =  0

const NO_COLLISION::UInt8   = 0
const RIGHT_LEFT::UInt8     = 1
const RIGHT_BLOCKADE::UInt8 = 2
const BLOCKADE_LEFT::UInt8  = 3

const DELETE_CURRENT::UInt8  = 1
const DELETE_ADJACENT::UInt8 = 2
const DELETE_BOTH::UInt8     = 3
const DEFAULT_VALUE::UInt8   = 4

mutable struct Particle
    pos::Float32
    init_pos::Float32
    vel::Int8
    left::Union{Nothing, Particle}
    right::Union{Nothing, Particle}
end


mutable struct ParticleInfo
    final_pos::Float64
    time_lived::Float64
    vel::Float64
end


mutable struct Line
    x_coords::Vector{Float64}
    y_coords::Vector{Float64}
    vel::Float64
end


COLLISION_TYPE_MAP = Dict(
    (RIGHT_VEL, RIGHT_VEL) => NO_COLLISION,
    (RIGHT_VEL, LEFT_VEL) => RIGHT_LEFT,
    (RIGHT_VEL, BLOCKADE_VEL) => RIGHT_BLOCKADE,

    (LEFT_VEL, LEFT_VEL) => NO_COLLISION,
    (LEFT_VEL, RIGHT_VEL) => NO_COLLISION,
    (LEFT_VEL, BLOCKADE_VEL) => NO_COLLISION,

    (BLOCKADE_VEL, BLOCKADE_VEL) => NO_COLLISION,
    (BLOCKADE_VEL, LEFT_VEL) => BLOCKADE_LEFT,
    (BLOCKADE_VEL, RIGHT_VEL) => NO_COLLISION,
)


function initalize_particle_linked_list(min_pos, max_pos, num_particles, prob_blockade)
    vel_weights = Weights([prob_blockade, (1 - prob_blockade) / 2, (1 - prob_blockade) / 2])
    velocities = sample([BLOCKADE_VEL, LEFT_VEL, RIGHT_VEL], vel_weights, num_particles)
    positions = sort(rand(Uniform(min_pos, max_pos), num_particles))

    head = Particle(positions[1], positions[1], velocities[1], nothing, nothing)
    prev = head

    for i = 2:num_particles
        curr = Particle(positions[i], positions[i], velocities[i], prev, nothing)
        prev.right = curr
        prev = curr
    end

    return head
end


function delete_particle(head, particle)
    if isnothing(particle.left) && isnothing(particle.right)
        return nothing
    elseif isnothing(particle.left)
        head = particle.right
        head.left = nothing
    elseif isnothing(particle.right)
        adj_left = particle.left
        adj_left.right = nothing
    else
        left = particle.left
        right = particle.right
        left.right = right
        right.left = left
    end

    return head
end


function find_next_collision_starting_node(head)
    curr = head
    collision_start = nothing
    smallest_dist = Inf

    while !isnothing(curr.right)
        collision_type = COLLISION_TYPE_MAP[(curr.vel, curr.right.vel)]

        if collision_type == NO_COLLISION
            curr = curr.right
            continue
        end

        distance = curr.right.pos - curr.pos

        if collision_type == RIGHT_LEFT
            distance /= 2
        end

        if distance < smallest_dist
            collision_start = curr
            smallest_dist = distance
        end
        curr = curr.right
    end

    return collision_start, smallest_dist
end


function perform_collision(
        head, collision_start, 
        left_right_arrow_outcomes, 
        right_arrow_blockade_outcomes, 
        blockade_left_arrow_outcomes
    )

    collision_type = COLLISION_TYPE_MAP[(collision_start.vel, collision_start.right.vel)]
    outcome = DEFAULT_VALUE

    if collision_type == RIGHT_LEFT
        outcome = pop!(left_right_arrow_outcomes)
    elseif collision_type == RIGHT_BLOCKADE
        outcome = pop!(right_arrow_blockade_outcomes)
    else
        outcome = pop!(blockade_left_arrow_outcomes)
    end

    if outcome == DELETE_CURRENT
        head = delete_particle(head, collision_start)
    elseif outcome == DELETE_ADJACENT
        head = delete_particle(head, collision_start.right)
    else
        head = delete_particle(head, collision_start)
        head = delete_particle(head, collision_start.right)
    end

    return head
end


@inline
function update_particle_info(particle, particle_info, distance, curr_time)
    particle_info[particle.init_pos].final_pos = particle.pos + (distance * particle.vel)
    particle_info[particle.init_pos].time_lived = curr_time + distance
end


function update_positions(head, particle_info, distance, curr_time)
    curr = head
    while !isnothing(curr)
        curr.pos += curr.vel * distance
        particle_info[curr.init_pos].final_pos = curr.pos
        particle_info[curr.init_pos].time_lived = curr_time + distance
        curr = curr.right
    end
end


function resolve_next_collision(
        head, particle_info, curr_time,
        left_right_arrow_outcomes, 
        right_arrow_blockade_outcomes, 
        blockade_left_arrow_outcomes
    )

    if isnothing(head)
        return nothing, 0
    end

    collision_start, distance = find_next_collision_starting_node(head)

    if isnothing(collision_start)
        # If there are no more collisions just progress the time step of the simulation
        # a bit and return
        update_positions(head, particle_info, 100, curr_time)
        return head, 100
    end

    # Just in case either the particle at the start of the collision or the adjacent particle to the
    # right of it are annihilated, or both, save both of their current positions and times.
    update_particle_info(collision_start, particle_info, distance, curr_time)
    update_particle_info(collision_start.right, particle_info, distance, curr_time)

    head = perform_collision(
        head, collision_start, 
        left_right_arrow_outcomes, 
        right_arrow_blockade_outcomes, 
        blockade_left_arrow_outcomes
    )

    update_positions(head, particle_info, distance, curr_time)
    return head, distance
end


function print_particle_counts(head)
    particle_type_count = Dict(LEFT_VEL => 0, RIGHT_VEL => 0, BLOCKADE_VEL => 0)
    curr = head

    while !isnothing(curr)
        particle_type_count[curr.vel] += 1
        curr = curr.right
    end

    println("<: ", particle_type_count[LEFT_VEL])
    println(">: ", particle_type_count[RIGHT_VEL])
    println("*: ", particle_type_count[BLOCKADE_VEL])
end


function simulate(;steps=100_000, min_pos=-1_000, max_pos=1_000, num_particles=100_000, p=0.25, a=0, α=0, β=0)
    head = initalize_particle_linked_list(min_pos, max_pos, num_particles, p)

    println("Before:")
    print_particle_counts(head)

    left_right_arrow_outcomes = sample(
        [DELETE_CURRENT, DELETE_ADJACENT, DELETE_BOTH], 
        Weights([a / 2, a / 2, 1 - a]), 
        num_particles
    )

    right_arrow_blockade_outcomes = sample(
        [DELETE_ADJACENT, DELETE_CURRENT, DELETE_BOTH], 
        Weights([α, β, 1 - (α + β)]),
        num_particles
    )

    blockade_left_arrow_outcomes = sample(
        [DELETE_CURRENT, DELETE_ADJACENT, DELETE_BOTH], 
        Weights([α, β, 1 - (α + β)]),
        num_particles
    )

    particle_info = Dict{Float64, ParticleInfo}()
    curr_time = 0

    curr = head
    while !isnothing(curr)
        particle_info[curr.init_pos] = ParticleInfo(curr.init_pos, 0.0, curr.vel)
        curr = curr.right
    end

    for _ = 1:steps
        head, time_delta = resolve_next_collision(
            head, particle_info, curr_time,
            left_right_arrow_outcomes, 
            right_arrow_blockade_outcomes, 
            blockade_left_arrow_outcomes)
        curr_time += time_delta
    end

    println("\nAfter ", steps, " step(s):")
    print_particle_counts(head)

    return particle_info
end


function create_diagram(particle_info, pos_min, pos_max)
    lines = []
    max_time_survived = 0

    for (pos, info) in particle_info
        x_coords = [pos, info.final_pos] 
        y_coords = [0.0, info.time_lived]
        push!(lines, Line(x_coords, y_coords, info.vel))

        if info.time_lived > max_time_survived
            max_time_survived = info.time_lived
        end
    end

    plt = plot(
        legend=false, 
        ylims=(0, max_time_survived * 1.5),
        xlims=(pos_min, pos_max), 
        axis=([], false)
    )

    for line in lines
        color = "Crimson"
        if line.vel == BLOCKADE_VEL
            color = "Dark Blue"
        end
        plot!(plt, (line.x_coords, line.y_coords), color=color)
    end

    gui(plt)
end


# If lines look too steep in resulting graphic, bump up the number
# of steps taken.

particle_info = simulate(
    ;steps=75, 
    num_particles=100, 
    min_pos=-50_000, 
    max_pos=50_000, 
    p=0.25,
    a=1/3,
    α=1/3, 
    β=1/3
)

create_diagram(particle_info, -50_000, 50_000)