module TypeStableDicts

export MixedKeyDict

struct MixedKeyDict{T<:Tuple} <: AbstractDict{Any,Any}
    dicts::T
end

Base.length(d::MixedKeyDict) = sum(length, d.dicts)

function Base.iterate(d::MixedKeyDict, state=(1,))
    index = first(state)
    res = iterate(d.dicts[index], Base.tail(state)...)
    if res == nothing
        if index < length(d.dicts)
            return iterate(d, (index+1,))
        else
            return nothing
        end
    else 
        return first(res), (index, Base.tail(res)...)
    end
end

Base.getindex(d::MixedKeyDict, key) = _getindex(d.dicts, key)

_getindex((d,)::Tuple{D,Vararg}, key::K) where {K,D<:AbstractDict{K}} = d[key]
_getindex(dicts, key) = _getindex(Base.tail(dicts), key)
_getindex(::Tuple{}, key) = KeyError(key)

#Base.mapfoldl

Base.merge(f::Function, d::MixedKeyDict, others::MixedKeyDict...) = _merge(f, (), d.dicts, (d->d.dicts).(others)...)
Base.merge(f, d::MixedKeyDict, others::MixedKeyDict...) = _merge(f, (), d.dicts, (d->d.dicts).(others)...)

function _merge(f, res, d, others...)
    ofsametype, remaining = _alloftype(Base.heads(d), ((),), others...)
    return _merge(f, (res..., merge(f, ofsametype...)), Base.tail(d), remaining...)
end

_merge(f, res, ::Tuple{}, others...) = _merge(f, res, others...)
_merge(f, res, d) = MixedKeyDict((res..., d...))
_merge(f, res, ::Tuple{}) = MixedKeyDict(res)

function _alloftype(ofdesiredtype::Tuple{Vararg{D}}, accumulated, d::Tuple{D,Vararg}, others...) where D
    return _alloftype((ofdesiredtype..., first(d)),
                      (Base.front(accumulated)..., (last(accumulated)..., Base.tail(d)...), ()),
                      others...)
end

function _alloftype(ofdesiredtype, accumulated, d, others...)
    return _alloftype(ofdesiredtype,
                      (Base.front(accumulated)..., (last(accumulated)..., first(d))),
                      Base.tail(d), others...)
end

function _alloftype(ofdesiredtype, accumulated, ::Tuple{}, others...)
    return _alloftype(ofdesiredtype,
                      (accumulated..., ()),
                      others...)
end

_alloftype(ofdesiredtype, accumulated) = ofdesiredtype, Base.front(accumulated)

end # module
