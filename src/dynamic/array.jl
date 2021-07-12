mutable struct DynamicRSArray{Tv,Tt,N,Tc} <: DynamicRArray{Tv,Tt,N}
    v::Vector{Tv}
    sz::Size{N}
    t::Tc
    dok::Dict{NTuple{N,Int},Tuple{Vector{Tt},Vector{Tv}}}
    rsz::Size{N}
    indmap::IndexMap{N}
    function DynamicRSArray(
            v::Vector,
            sz::Size{N},
            t::Tc,
            dok::Dict{NTuple{N,Int},Tuple{Vector{Tt},Vector{Tv}}},
            rsz::Size{N},
            indmap::IndexMap{N},
        ) where {Tv,Tt,N,Tc<:AbstractClock{Tt}}
        checksize(sz, v, indmap)
        bounds = map(Base.oneto, rsz.sz)
        for (ind, (ti, vi)) in dok
            Base.checkbounds_indices(Bool, bounds, ind) ||
                throw(ArgumentError("index in dok is out of bounds"))
            checksize(ti, vi)
        end
        # return new{Tv,Tt,N,Tc}(v, sz, t, dok, rsz, indmap)
    end
end

function DynamicRArray(t::AbstractClock, A::AbstractArray)
    v = similar(A, length(A))
    sz = Size(A)
    dok = Dict{NTuple{ndims(A),Int},Tuple{Vector{eltype(t)},Vector{eltype(A)}}}()
    for (i, ind) in enumerate(IndexMap(sz))
        dok[ind] = ([currenttime(t)], [v[i]])
    end
    rsz = Size(A)
    indmap = IndexMap(axes(A))
    return DynamicRSArray(v, sz, t, dok, rsz, indmap)
end

function Base.setindex!(A::DynamicRSArray, v, i::Int)
    @boundscheck checkbounds(A, i)
    A.v[i] = v
    ind = A.indmap[i]
    push!(A.V[ind], v)
    push!(A.T[ind], currenttime(A.t))
end