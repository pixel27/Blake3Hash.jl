# MIT License
#
# Copyright (c) 2020 Joshua E Gentry

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# -----------------------------------------------------------------------------------------
# Constants for the tests.
const TOTAL_SIZE  = 1024
const END_SIZE    = 256
const STEP_SIZE   = 32

# -----------------------------------------------------------------------------------------
# Define the iterator to iterate over all the hash chunks.
struct StressChunks
    max::Int
end

function first(
            iter::StressChunks
        )::Vector{Int}
    return [ iter.max ]
end

function next(
            iter::StressChunks,
            prev::Union{Vector{Int}, Nothing} = nothing
        )::Bool

    while length(prev) > 0 && prev[end] <= STEP_SIZE
        pop!(prev)
    end

    if length(prev) == 0
        return false
    end

    prev[end] -= STEP_SIZE
    push!(prev, iter.max - sum(prev))

    return true
end

function increased_size(
            iter::StressChunks
        )::Union{StressChunks, Nothing}
    if iter.max == END_SIZE
        return nothing
    end
    return StressChunks(iter.max + STEP_SIZE)
end

mutable struct Stress
    front::Union{StressChunks, Nothing}
    back::Union{StressChunks, Nothing}
    Stress() = new(nothing, nothing)
end

struct StressState
    front::Union{Vector{Int}, Nothing}
    back::Union{Vector{Int}, Nothing}
end

function Base.iterate(
            iter::Stress,
            state::Union{StressState, Nothing} = nothing
        )::Union{Tuple{Vector{Int}, StressState}, Nothing}

    function result(st::StressState)
        if st.front === nothing
            return vcat(TOTAL_SIZE - sum(st.back), st.back)
        elseif st.back === nothing
            return vcat(st.front, TOTAL_SIZE - sum(st.front))
        end
        return vcat(st.front, TOTAL_SIZE - sum(st.front) - sum(st.back), st.back)
    end

    # -------------------------------------------------------------------------------------
    # Not state, let's get this show on the road.
    if state === nothing
        iter.back = StressChunks(STEP_SIZE)
        state     = StressState(nothing, first(iter.back))
        return (result(state), state)
    end

    # -------------------------------------------------------------------------------------
    # If the back iterator is nothing, create the smallest one.
    if iter.back === nothing
        iter.back = StressChunks(STEP_SIZE)
        state     = StressState(state.front, first(iter.back))
        return (result(state), state)
    end

    # -------------------------------------------------------------------------------------
    # Increment the back iterator.
    if next(iter.back, state.back) == true
        return (result(state), state)
    end

    # -------------------------------------------------------------------------------------
    # Back iterator completed, increase it's size and grab the first item.
    iter.back = increased_size(iter.back)

    if iter.back !== nothing
        state = StressState(state.front, first(iter.back))
        return (result(state), state)
    end

    # -------------------------------------------------------------------------------------
    # Back iterator has finished with END_SIZE, clear it out before incrementing the front
    # iterator.
    iter.back = nothing

    # -------------------------------------------------------------------------------------
    # Back iterator has finished with END_SIZE, create the front iterator if needed.
    if iter.front === nothing
        iter.front = StressChunks(STEP_SIZE)
        state      = StressState(first(iter.front), nothing)
        return (result(state), state)
    end

    # -------------------------------------------------------------------------------------
    # Back iterator has finished with END_SIZE, increment the front iterator.
    if next(iter.front, state.front) == true
        state = StressState(state.front, nothing)
        return (result(state), state)
    end

    # -------------------------------------------------------------------------------------
    # Front iterator completed, increase it's size and grab the first item.
    iter.front = increased_size(iter.front)

    if iter.front !== nothing
        state = StressState(first(iter.front), nothing)
        return (result(state), state)
    end

    # -------------------------------------------------------------------------------------
    # Front iterator has finsihed with END_SIZE, all done.
    return nothing
end

struct StressIter
    data::Vector{UInt8}
    stress::Stress
    StressIter(data) = new(data, Stress())
end

function Base.iterate(iter::StressIter, state=nothing)
    next = iterate(iter.stress, state)

    if next === nothing
        return nothing
    end

    data = Vector()

    pos = 1
    for size in next[1]
        push!(data, view(iter.data, pos:pos+size-1))
        pos += size
    end

    return (data, next[2])
end
