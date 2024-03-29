import Distributions: Uniform
import StatsBase: sample, Weights

const LEFT_VEL::Int8     = -1
const RIGHT_VEL::Int8    =  1
const BLOCKADE_VEL::Int8 =  0

const NO_COLLISION::UInt8   = 0
const RIGHT_LEFT::UInt8     = 1
const RIGHT_BLOCKADE::UInt8 = 2
const BLOCKADE_LEFT::UInt8  = 3

const DELETE_CURRENT::UInt8    = 1
const DELETE_ADJACENT::UInt8   = 2
const DELETE_BOTH::UInt8       = 3
const GENERATE_BLOCKADE::UInt8 = 4
const DEFAULT_VALUE::UInt8     = 5

mutable struct Particle
    pos::Float32
    vel::Int8
    left::Union{Nothing, Particle}
    right::Union{Nothing, Particle}
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

    head = Particle(positions[1], velocities[1], nothing, nothing)
    prev = head

    for i = 2:num_particles
        curr = Particle(positions[i], velocities[i], prev, nothing)
        prev.right = curr
        prev = curr
    end

    return head
end


function insert_particle_right(particle_to_insert_at, particle_to_insert)
    right = particle_to_insert_at.right
    particle_to_insert_at.right = particle_to_insert
    particle_to_insert.left = particle_to_insert_at
    particle_to_insert.right = right

    if !isnothing(right)
        right.left = particle_to_insert
    end
end


function insert_particle_left(particle_to_insert_at, particle_to_insert)
    # This function will only be called if we're inserting a particle to the 
    # the left of the current head, so that's the only case that needs to be
    # dealt with.
    head = particle_to_insert
    head.right = particle_to_insert_at
    particle_to_insert_at.left = head
    return head
end


function delete_particle(head, particle)
    if isnothing(particle.left)
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
    head, collision_start, midpoint, 
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
    elseif outcome == GENERATE_BLOCKADE
        head = delete_particle(head, collision_start)
        head = delete_particle(head, collision_start.right)

        generated_blockade = Particle(midpoint, BLOCKADE_VEL, nothing, nothing)

        # If the head of the linked list was the left particle deleted, we need to do a left insertion, since
        # the head of the linked list had no left. Otherwise, a right insertion needs to be performed.
        if isnothing(collision_start.left)
            head = insert_particle_left(head, generated_blockade)
        else
            insert_particle_right(collision_start.left, generated_blockade)
        end
    else
        head = delete_particle(head, collision_start)
        head = delete_particle(head, collision_start.right)
    end

    return head
end


function update_positions(head, distance)
    curr = head
    while !isnothing(curr)
        curr.pos += curr.vel * distance
        curr = curr.right
    end
end


function resolve_next_collision(head, left_right_arrow_outcomes, right_arrow_blockade_outcomes, blockade_left_arrow_outcomes)
    collision_start, distance = find_next_collision_starting_node(head)

    if isnothing(collision_start)
        return head, false
    end

    # Get the midpoint between the particles incase it's a left-right arrow collision and we need
    # to generate a blockade where they meet.
    midpoint = (collision_start.pos + collision_start.right.pos) / 2

    head = perform_collision(
        head, collision_start, midpoint, 
        left_right_arrow_outcomes, 
        right_arrow_blockade_outcomes, 
        blockade_left_arrow_outcomes
    )

    update_positions(head, distance)
    return head, true
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


function simulate(;steps=100_000, min_pos=-1_000, max_pos=1_000, num_particles=100_000, p=0.25, a=0, b=0, α=0, β=0)
    head = initalize_particle_linked_list(min_pos, max_pos, num_particles, p)

    println("Before:")
    print_particle_counts(head)

    left_right_arrow_outcomes = sample(
        [DELETE_CURRENT, DELETE_ADJACENT, GENERATE_BLOCKADE, DELETE_BOTH], 
        Weights([a / 2, a / 2, b, 1 - (a + b)]), 
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

    steps_taken = 0
    for _ = 1:steps
        steps_taken += 1

        head, collisions_occuring = resolve_next_collision(
            head, left_right_arrow_outcomes, 
            right_arrow_blockade_outcomes, 
            blockade_left_arrow_outcomes
        )

        if !collisions_occuring
            println(
                "\nSimulation ended after ", 
                steps_taken, 
                " step(s) as no more collisions could occur."
            )
            break
        end
    end

    println("\nAfter ", steps_taken, " step(s):")
    print_particle_counts(head)
end


simulate()
