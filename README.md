# Overview

This project was started and primarily written collaboratively during the 2023 Baruch Discrete Mathematics REU. It's purpose is to simulate the four-parameter coalescing ballistic annihilation
(FCBA) probablistic model. The basic overview of the model is that infintely many particles are randomoly, but uniformly placed on the real number line, and assigned velocities of 0, 1, or -1 with certain probabilities. The reactions that occur when particles meet are also dictated by relevant probabilites. More details of the model can be observed in the implementation of the simulation.

The primary value the simulation code is used to experimentally explore is the smallest density of
stationary particles that gives a non-zero (i.e. positive) probability of any stationary particle
surviving. An explict formula for this value, known as $P_c$, was calculated during the REU program,
and this simulation code was written to provide experimental confirmation of the correctness of the
discovered formula.

More specfically, particles given a velocity of 0, 1, or -1 will be referred to as _blockades_, 
_right arrows_, or _left arrows_ respectively. Blockades are assigned with a probability of $p$
(where $ p \in [0, 1]$), and arrows are assigned with a probability of $(1 - p) / 2$.

Further, the reactions that can occur when two particles meet are determined by the
four-parameters probability parameters $a, b, \alpha, \beta$ (again, 
where $a, b, \alpha, \beta \in [0, 1]$). An full overview of all of the possible reactions and
their probabilities is given in the image below:

![FCBA model summary](media\fcba_model_summary.png)

Where a particle with a dot over it denotes a blockade, a particle with a right arrow over it
denotes a right arrow, a particle with a left arrow over it denotes a left arrow, and the empty
set symbol $\emptyset$ denotes a mutal annihilation reaction.

Thus, more formally, the value $P_c$ is the minimum value of $p$ such that there is a positive
probability of any blockade suriving the evolution of the FCBA model.

It should be noted that this README is meant as a supporting document to the primary paper
concering the work done on FCBA that is currently being submitted to journals. Thus, a comprehensive exposition of FCBA will not be given, and certain details will be omitted.

# Usage

The code for this project is written in Julia, and an installation of the language's compiler is
needed to run the code. Download links for the compiler and information on the Julia
language can be found on Julia's offical website: https://juliastats.org/.

The two files included in this project, `ba.jl` and `ba_graphics.jl`, both serve as entry points
into running simulations. The former file, `ba.jl`, is intended to be used to simulate large
numbers of particles, recording the initial and final number of particles of each respective velocity.

An example of the output of running `ba.jl` is shown below:

```
Before:
<: 3736
>: 3738
*: 2526

Simulation ended after 4977 step(s) as no more collisions could occur.

After 4977 step(s):
<: 30
>: 10
*: 8
```

It should be noted that `<`, `>`, and `*` denote right arrows, left arrows, and blockades respectively.

Inside of the `ba.jl` file, the `simulate` function can be passed a variety of keyword arguments to
tweak the parameters of the FCBA model that is being simulated. An example of calling `simulate`
with the non-default arguments is shown below:

```
simulate(
    ;steps=10_000, 
    num_particles=10_000, 
    min_pos=-1_000, 
    max_pos=1_000, 
    p=0.15,
    a=0.35,
    b=0.35,
    α=1/3, 
    β=1/3
)
```

With each of the parameters corresponding to various attributes of the FCBA model. A quick overview
of each keyword argument is listed below:

* `steps:` This argument can intuively be thought of as the number of times a collision should
attempted to be search for and resolved. It's better to set this parameter higher, since, as can
be the seen in the example output of running `ba.jl` above, the program is designed to automatically
stop running when it is no longer possible for collisions to occur.

* `num_particles:` The number of particles to run the simulation with.

* `min_pos` and `max_pos`: Both arguments together give the closed-interval of the real number line
the potential particle locations will be randomly, uniformly sampled from.

* `p`: The probability blockades are assigned.

* `a`: The probability an arrow surivies a collision with another arrow.

* `b`: The probability when two arrows hit they produce a new blockade at the location of their
collision.

* `α`: The probability an arrow survives it's collision with a blockade.

* `β`: The probability a blockade surivies it's collision with an arrow.

Alternatively, `ba_graphics.jl` can be run to produce images of time-space diagrams of FCBA.
An example of such a picture is given below:

![Example FCBA graphic](media\ba_pic_p15_all333_4.png)

Where particle position is on the x-axis and particle survival time is on the y-axis. Red lines
are arrows and blue lines are blockades.

Like `ba.jl`, the entry point of `ba_graphics.jl` is also it's `simulation` function which has
an identical signature to the `simulation` function in `ba.jl`.

# Licensing

The license chosen for this project is the commonly used [MIT License](https://choosealicense.com/licenses/mit/#). It was chosen to encourge a spirit of open collaboration.
