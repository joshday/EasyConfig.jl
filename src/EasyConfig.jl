module EasyConfig

export Config, @config

#------------------------------------------------------------------------------# Undefined
# Lazy path of nested dicts
struct Undefined{T <: AbstractDict{Symbol, Any}}
    parent::T
    path::Vector{Symbol}
end
parent(o::Undefined) = getfield(o, :parent)
path(o::Undefined) = getfield(o, :path)

Base.getindex(o::Undefined, k::Symbol) = Undefined(parent(o), [path(o)..., k])
function Base.setindex!(o::Undefined{T}, v, key::Symbol) where {T}
    c = parent(o)
    for k in path(o)
        c[k] = T()
        c = c[k]
    end
    c[key] = v
    return parent(o)
end
Base.getproperty(o::Undefined, k::Symbol) = getindex(o, k)
Base.setproperty!(o::Undefined, k::Symbol, v) = setindex!(o, v, k)


#------------------------------------------------------------------------------# Settings
@kwdef struct Settings
    autoconvert::Vector{Union{UnionAll, DataType}} = [AbstractDict{Symbol}, NamedTuple]
end
settings::Settings = Settings()

#------------------------------------------------------------------------------# Config
struct Config{D <: AbstractDict{Symbol, Any}} <: AbstractDict{Symbol, Any}
    dict::D
    Config(dict::D) where {D <: AbstractDict{Symbol, Any}} = new{D}(dict)
end
Config() = Config(Dict{Symbol,Any}())
Config(x::AbstractDict{Symbol}) = Config{Dict{Symbol,Any}}(x)
Config{D}() where {D} = Config(D())
function Config{D}(x::AbstractDict{Symbol}) where {D}
    out = Config{D}()
    for (k, v) in x
        out[k] = v
    end
    out
end
function Config(x::Pair...; kw...)
    out = Config()
    for (k, v) in Iterators.flatten((x, kw))
        out[k] = v
    end
    out
end

dict(o::Config) = getfield(o, :dict)

## Getting and Setting ##
Base.getindex(o::Config, k::Symbol) = get(o, k, Undefined(o, [k]))
Base.setindex!(o::Config, v, k::Symbol) = setindex!(dict(o), v, k)
Base.setindex!(o::T, v::AbstractDict{Symbol}, k::Symbol) where {T <: Config} = setindex!(dict(o), T(v), k)
Base.setindex!(o::T, v::T, k::Symbol) where {T <: Config} = setindex!(dict(o), v, k)

Base.getindex(o::Config, k::AbstractString) = getindex(o, Symbol(k))
Base.setindex!(o::Config, v, k::AbstractString) = setindex!(o, v, Symbol(k))

Base.propertynames(o::Config) = keys(o)
Base.getproperty(o::Config, k::Symbol) = getindex(o, k)
Base.setproperty!(o::Config, k::Symbol, v) = setindex!(o, v, k)

## AbstractDict interface ##
Base.get(o::Config, k::Symbol, default) = get(dict(o), k, default)
Base.get(o::Config, k::AbstractString, default) = get(o, Symbol(k), default)
Base.iterate(o::Config, s...) = iterate(dict(o), s...)
Base.length(o::Config) = length(dict(o))
Base.empty!(o::Config) = (empty!(dict(o)); o)
Base.delete!(o::Config, k::Symbol) = (delete!(dict(o), k); o)
Base.delete!(o::Config, k::AbstractString) = delete!(o, Symbol(k))
Base.merge(a::Config, b::Config) = Config(merge(dict(a), dict(b)))
Base.merge!(a::Config, b::Config) = Config(merge!(dict(a), dict(b)))
Base.copy(o::Config) = Config(copy(dict(o)))

#------------------------------------------------------------------------------# show
# What gets used to show nested Configs by the AbstractDict show method:
function Base.show(io::IO, o::Config)
    print(io, "Config(")
    join(io, map(((k, v),) -> "$(repr(k)) => $(repr(v; context=io))", collect(o)), ", ")
    print(io, ')')
end

#------------------------------------------------------------------------------# deepmerge
# `merge`, but will update the keys of a nested dict rather than replacing the dict entirely
function deepmerge!(a::T, b::AbstractDict) where {T <: AbstractDict}
    foreach(pairs(b)) do (k, v)
        old = get(a, k, nothing)
        a[k] = v isa AbstractDict ? deepmerge!(old isa AbstractDict ? old : T(), v) : v
    end
    return a
end

deepmerge(a, b) = deepmerge!(deepmerge!(Config(), a), b)


#-----------------------------------------------------------------------------# @config
"""
    @config expr

Create a `Config` with a NamedTuple-like or block syntax.  The following examples create equivalent `Config`s:

    @config (x.one=1, x.two=2, z=3)

    @config x.one=1 x.two=2 z=3

    @config begin
        x.one = 1
        x.two = 2
        z = 3
    end

    let
        c = Config()
        c.x.one = 1
        c.x.two = 2
        c.z = 3
    end
"""
macro config(ex...)
    args = length(ex) == 1 ? _config_args(only(ex)) : collect(ex)
    all(x -> Meta.isexpr(x, :(=), 2), args) || error("@config expects `key = value` expressions")
    c = gensym("config")
    body = map(x -> :($(_prepend(c, x.args[1])) = $(x.args[2])), args)
    esc(Expr(:block, :(local $c = $Config()), body..., c))
end

function _config_args(ex)
    Meta.isexpr(ex, :block) && return filter(x -> !(x isa LineNumberNode), ex.args)
    Meta.isexpr(ex, :tuple) && return ex.args
    return [ex]
end

_prepend(c, ex::Symbol) = :($c.$ex)
function _prepend(c, ex)
    Meta.isexpr(ex, :., 2) || error("@config expects keys like `x` or `x.y.z`, got: $ex")
    Expr(:., _prepend(c, ex.args[1]), ex.args[2])
end

end # module
