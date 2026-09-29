module EasyConfig

export Config

#------------------------------------------------------------------------------# Undefined
# Lazy path of nested dicts
struct Undefined{T <: AbstractDict{Symbol, Any}}
    parent::T
    path::Vector{Symbol}
end
parent(o::Undefined) = getfield(o, :parent)
path(o::Undefined) = getfield(o, :keys)

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
end
Config() = Config(Dict{Symbol,Any}())
Config{D}() where {D} = Config(D())
Config{D}(x::AbstractDict{Symbol}) where {D} = Config(D((k => string(v) for (k,v) in x)...))

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

# #-----------------------------------------------------------------------------# @config
# """
#     @config expr

# Create a `Config` with a NamedTuple-like or block syntax.  The following examples create equivalent `Config`s:

#     @config (x.one=1, x.two=2, z=3)

#     @config x.one=1 x.two=2 z=3

#     @config begin
#         x.one = 1
#         x.two = 2
#         z = 3
#     end

#     let
#         c = Config()
#         c.x.one = 1
#         c.x.two = 2
#         c.z = 3
#     end
# """
# macro config(ex...)
#     exprs = collect(ex)
#     if length(exprs) == 1
#         ex = only(exprs)
#         if ex.head == :block
#             ex = Expr(:tuple, filter(x -> !(x isa LineNumberNode), ex.args)...)
#         end
#     else
#         ex = Expr(:tuple, exprs...)
#     end
#     ex.head == :tuple || error("@config input must be a tuple")
#     all(x -> x.head == :(=), ex.args) || error("Unexpected syntax in @config")
#     x = gensym()
#     out = Expr(:block, :(local $x = Config()))
#     for val in ex.args
#         lhs, rhs = val.args
#         push!(out.args, :($(_prepend(x, lhs)) = $rhs))
#     end
#     push!(out.args, x)
#     esc(out)
# end

# _prepend(val, e::Symbol) = :($val.$e)
# _prepend(val, e) = e.head == :. && (e.args[1] = _prepend(val, e.args[1]); e)
end # module
