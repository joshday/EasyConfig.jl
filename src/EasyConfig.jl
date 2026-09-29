module EasyConfig

export Config

#------------------------------------------------------------------------------# Undefined
# Lazy path of nested dicts
struct Undefined{T <: AbstractDict{Symbol, Any}}
    parent::T
    keys::Vector{Symbol}
end
parent(o::Undefined) = getfield(o, :parent)
keys(o::Undefined) = getfield(o, :keys)

Base.getindex(o::Undefined, k::Symbol) = Undefined(parent(o), [keys(o)..., k])
function Base.setindex!(o::Undefined{T}, v, key::Symbol) where {T}
    c = parent(o)
    for k in keys(o)
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

Base.getindex(o::Config, k::AbstractString) = getindex(o, Symbol(k))
Base.setindex!(o::Config, v, k::AbstractString) = setindex!(o, v, Symbol(k))

Base.getproperty(o::Config, k::Symbol) = getindex(o, k)
Base.setproperty!(o::Config, k::Symbol, v) = setindex!(o, v, k)

## AbstractDict interface ##
Base.get(o::Config, k::Symbol, default) = get(dict(o), k, default)
Base.iterate(o::Config, s...) = iterate(dict(o), s...)
Base.length(o::Config) = length(dict(o))



#------------------------------------------------------------------------------# show
# What gets used to show nested Configs by the AbstractDict show method:
function Base.show(io::IO, o::Config)
    print(io, "(")
    join(io, map(((k, v),) -> "$(repr(k)) => $(repr(v; context=io))", collect(o)), ", ")
    print(io, ')')
end

# #-----------------------------------------------------------------------------# utils
# # Turn struct into NamedTuple
# fields(x::T) where {T} = NamedTuple{fieldnames(T)}(getfield.(Ref(x), fieldnames(T)))


# #-----------------------------------------------------------------------------# Key
# """
#     Key(x::AbstractString; sep = :auto)
#     Key(parts::Symbol...; sep::Char)

# An AbstractString represented internally as a `Vector{Symbol}` and a separator (`Char`).
# """
# struct Key <: AbstractString
#     parts::Vector{Symbol}
#     sep::Char
# end
# Key(x::Symbol...; sep::Char='.') = Key(collect(x), sep)
# function Key(x::AbstractString; sep = :auto)
#     if sep === :auto
#         nonletters = filter(!isletter, x)
#         countmap = Dict(x => count(==(x), nonletters) for x in unique(nonletters))
#         isempty(countmap) && return Key([Symbol(x)], '.')
#         _, char = findmax(countmap)
#         Key(Symbol.(split(x, char; keepempty=false)), char)
#     else
#         Key(Symbol.(split(x, sep; keepempty=false)), sep)
#     end
# end

# parts(o::Key) = getfield(o, :parts)
# sep(o::Key) = getfield(o, :sep)

# Base.getproperty(o::Key, x::Symbol) = Key([parts(o)..., x], sep(o))

# _string(o::Key) = join(parts(o), sep(o))
# Base.show(io::IO, o::Key) = print(io, styled"{bright_cyan:$(repr(_string(o)))}")
# Base.ncodeunits(o::Key) = ncodeunits(_string(o))
# Base.iterate(o::Key, i::Integer...) = iterate(_string(o), i...)
# Base.length(o::Key) = length(_string(o))

# function Base.:*(a::Key, b::Key)
#     sep(a) == sep(b) || error("Cannot join `Key`s with different separators.  Found $(sep(a)) and $(sep(b)).")
#     Key(vcat(parts(a), parts(b)), sep(a))
# end

# function strip_prefix(o::Key, prefix::Key)
#     sep(o) == sep(prefix) || error("Cannot join `Key`s with different separators.  Found $(sep(o)) and $(sep(prefix)).")
#     all(x==y for (x, y) in zip(parts(o), parts(prefix))) || error("$prefix is not a prefix of $o")
#     Key(parts(o)[length(parts(prefix)) + 1:end], sep(o))
# end

# parent(o::Key) = Key(parts(o)[1:end-1], sep(o))


# #-----------------------------------------------------------------------------# ref interface
# is_key(o::Ref, key::Key) = true
# is_val(o::Ref, key::Key, val)  = true
# about(ref, key::Key) = "No information provided for $key of $ref."



# # about(o::KV, key::Key) = about(ref(o), key)

# function check(ref::T, key::Key) where {T}
#     idx = findall(startswith(key), ref_keys(ref))
#     length(idx) > 0 || error("Key $key not found in reference $ref.")
# end

# # function check(ref::T, key::Key, val) where {T}
# #     check(ref, key)
# #     if !is_valid(ref, key, val)
# #         error("Reference::$T invalid value for key $key:  $val.  See `about(ref, key)`.")
# #     end
# # end

# # # # ref methods that use interface
# # # is_full_path(ref, o::Key) = o in ref_keys(ref)
# # # is_partial_path(ref, o::Key) = any(startswith(o), ref_keys(ref))


# #-----------------------------------------------------------------------------# Undefined
# struct Undefined
#     about
# end
# Base.show(io::IO, o::Undefined) = print(io, "Undefined: ", o.about)

# #-----------------------------------------------------------------------------# KV
# struct KV{R} <: AbstractDict{Key, Any}
#     keys::Vector{Key}
#     values::Vector
#     prefix::Key
#     ref::R
#     function KV(pairs::Pair...; ref::R = nothing, path=Key()) where {R}
#         keys = collect(Key.(first.(pairs)))
#         vals = collect(Any, last.(pairs))
#         new{R}(keys, vals, path, ref)
#     end
# end

# prefix(o::KV) = getfield(o, :prefix)
# ref(o) = getfield(o, :ref)
# root(o::KV) = KV(getfield(o, :keys), getfield(o, :values), Key(), ref(o))
# parent(o::KV) = KV(getfield(o, :keys), getfield(o, :values), parent(prefix(o)), ref(o))

# key_idxs(o::KV, prefix::Key) = findall(startswith(prefix), getfield(o, :keys))
# key_idxs(o::KV) = key_idxs(o, prefix(o))

# ref_keys(o::KV) = ref_keys(ref(o))
# about(o::KV, k::Key) = about(ref(o), k)

# function Base.keys(o::KV)
#     full_keys = getfield(o, :keys)[key_idxs(o)]
#     strip_prefix.(full_keys, prefix(o))
# end
# Base.values(o::KV) = getfield(o, :values)[key_idxs(o)]

# Base.iterate(o::KV, x...) = iterate(keys(o) .=> values(o), x...)
# Base.length(o::KV) = length(keys(o))



# function Base.getindex(o::KV{Nothing}, _k::AbstractString)
#     k = prefix(o) * Key(_k)
#     kys = getfield(o, :keys)
#     # Case 1) Key already exists
#     i = findfirst(==(k), kys)
#     !isnothing(i) && return values(o)[i]

#     # Case 2) Full key exists in ref
#     k in ref_keys(o) && return Undefined(about(o, k))

#     # Case 3) k is a prefix of another key in ref
#     any(startswith(k), kys) && return KV(kys, getfield(o, :values), k, ref(o))

#     error("Key :$k not found in reference $(ref(o)).")
# end

# function Base.setindex!(o::KV, v, _k::AbstractString)
#     k = Key(_k)
#     is_valid(ref(o), k, v) || error("Reference::$ref invalid value for key $k:  $v.  See `about(ref, $(repr(k)))`.")
#     i = findfirst(==(k), keys(o))
#     if isnothing(i)
#         push!(keys(o), k)
#         push!(values(o), v)
#     else
#         keys(o)[i] = k
#         values(o)[i] = v
#     end
# end

# function Base.propertynames(o::KV)
#     map(keys(o)) do k
#         parts(k)[1]
#     end
# end
# Base.getproperty(o::KV, k::Symbol) = getindex(o, string(k))

# #-----------------------------------------------------------------------------# ref interface
# ref_keys(::Nothing) = Key[]
# is_valid(::Nothing, key::Key, val) = true
# about(ref, key::Key) = "No information provided for $key of $ref."



# ref_keys(o::KV) = ref_keys(ref(o))
# about(o::KV, key::Key) = about(ref(o), key)

# function check(ref::T, key::Key) where {T}
#     idx = findall(startswith(key), ref_keys(ref))
#     length(idx) > 0 || error("Key $key not found in reference $ref.")
# end

# function check(ref::T, key::Key, val) where {T}
#     check(ref, key)
#     if !is_valid(ref, key, val)
#         error("Reference::$T invalid value for key $key:  $val.  See `about(ref, key)`.")
#     end
# end






#-----------------------------------------------------------------------------# Undefined
# struct Undefined{T}
#     parent::T
#     path::Vector{Symbol}
# end
# parent(o::Undefined) = getfield(o, :parent)
# path(o::Undefined) = getfield(o, :path)
# Base.show(io::IO, o::Undefined) = print(io, styled"{bright_yellow:Undefined($(typeof(parent(o)))): $(join(path(o), '.'))}")

# Base.getindex(o::Undefined, k::Symbol) = Undefined(parent(o), [path(o)..., k])

# Base.propertynames(o::Undefined) =
# Base.getproperty(o::Undefined, k::Symbol) = getindex(o, k)
# Base.setproperty!(o::Undefined, k::Symbol, v) = setindex!(o, v, k)


#-----------------------------------------------------------------------------# Reference interface
# ref_keys(ref) = keys(ref)
# ref_value(ref, k) = ref[k]

# iskey(ref, k) = k in ref_keys(ref)
# isval(ref, k, v) = ref_

# iskey(::Nothing, k) = true
# isval(::Nothing, k, v) = true

# key_error(ref, k) = error("$ref does not have key $k.")
# val_error(ref, k, v) = error("$ref does not allow value $v for key $k.")

# check(o, k) = iskey(ref(o), k) || key_error(ref(o), k)
# check(o, k, v) = check(o, k) && isval(ref(o), k, v) || val_error(ref(o), k, v)

#-----------------------------------------------------------------------------# prune!
prune!(o::AbstractDict) = prune!(isempty, o)

function prune!(f, o::AbstractDict)
    for (k, v) in o
        if v isa AbstractDict
            f(v) ? delete!(o, k) : prune!(f, v)
        end
    end
    return o
end

# #-----------------------------------------------------------------------------# Config
# struct Config <: AbstractDict{Symbol, Any}
#     dict::OrderedDict{Symbol, Any}
# end
# function Config(x::Pair...; kw...)
#     Config(OrderedDict{Symbol,Any}((Symbol(x[1]) => _config(x[2]) for x in x)..., (k => _config(v) for (k,v) in kw)...))
# end

# Config(dict::Union{NamedTuple, AbstractDict}) = _config(dict)
# _config(x) = x
# _config(x::AbstractArray) = _config.(x)
# _config(x::AbstractDict) = Config(OrderedDict{Symbol, Any}((Symbol(k) => _config(v) for (k, v) in x)...))
# _config(kw::NamedTuple) = Config(; kw...)
# _config(x::Pair{<:Union{AbstractString, Symbol}, T}) where {T} = Config(Symbol(x[1]) => _config(x[2]))

# dict(o) = getfield(o, :dict)

# for f in (:length, :keys, :values, :iterate, :setindex!, :get, :get!)
#     @eval Base.$f(o::Config, x...) = $f(dict(o), x...)
# end
# Base.getindex(o::Config, k::Symbol) = get!(dict(o), k, Config())
# for f in (:empty!, :delete!)
#     @eval Base.$f(o::Config, x...) = ($f(dict(o), x...); o)
# end
# Base.merge!(a::Config, b::Config) = (merge!(dict(a), dict(b)); a)
# Base.merge(a::Config, b::Config) = merge!(copy(a), b)
# Base.delete!(o::Config, k::AbstractString) = delete!(o, Symbol(k))
# Base.copy(o::Config) = Config(copy(dict(o)))
# Base.isempty(o::Config) = isempty(prune!(o))

# Base.getindex(o::Config, k::AbstractString) = getindex(o, Symbol(k))
# Base.setindex!(o::Config, v, k::AbstractString) = setindex!(o, v, Symbol(k))
# Base.get(o::Config, k::AbstractString, default) = get(o, Symbol(k), default)
# Base.get!(o::Config, k::AbstractString, default) = get!(o, Symbol(k), default)

# Base.propertynames(o::Config) = Symbol.(keys(o))
# Base.getproperty(o::Config, k::Symbol) = getindex(o, k)
# Base.getproperty(o::Config, k::AbstractString) = getindex(o, k)
# Base.setproperty!(o::Config, k::Symbol, v) = setindex!(o, v, k)
# Base.setproperty!(o::Config, k::AbstractString, v) = setindex!(o, v, k)


#-----------------------------------------------------------------------------#


# #-----------------------------------------------------------------------------# Key
# struct Key
#     parts::Vector{Symbol}
# end
# parts(o::Key) = getfield(o, :parts)

# Key(x::Symbol...) = Key(Symbol[x...])
# Key(x::AbstractString) = Key(Symbol.(split(x, '.')))
# Key(x::Key) = x
# Base.string(o::Key) = join(parts(o), '.')

# Base.:(==)(a::Key, b::Key) = parts(a) == parts(b)
# Base.hash(o::Key, h::UInt) = hash(parts(o), h)

# const KeyType = Union{Symbol, AbstractString, Key}

# Base.:*(o::Key, k::KeyType) = Key([parts(o)..., parts(Key(k))...])

# Base.show(io::IO, o::Key) = print(io, styled"{bright_cyan:$(repr(string(o)))}")
# Base.getindex(o::Key, i::Integer) = parts(o)[i]
# Base.length(o::Key) = length(parts(o))
# Base.iterate(o::Key, i::Int=1) = i > length(o) ? nothing : (o[i], i + 1)

# Base.getproperty(o::Key, x::Symbol) = o * x

# #-----------------------------------------------------------------------------# Undefined
# struct Undefined{T}
#     parent::T
#     path::Key
# end
# Base.show(io::IO, o::Undefined) = print(io, styled"{bright_red:Undefined($(string(o.path)))}")
# Base.getindex(o::Undefined, k::KeyType) = o.parent[k]

# #-----------------------------------------------------------------------------# Config
# struct Config{R} <: AbstractDict{Symbol, Any}
#     dict::OrderedDict{Key, Any}
#     prefix::Key
#     ref::R
# end

# dict(o)     = getfield(o, :dict)
# prefix(o)   = getfield(o, :prefix)
# ref(o)      = getfield(o, :ref)
# isdef(o)    = getfield(o, :isdef)

# function dict_subset(o::Config)
#     filter(dict(o)) do (k, v)
#         all(a == b for (a,b) in zip(k, prefix(o)))
#     end
# end
# Base.iterate(o::Config, i=1) = iterate(dict_subset(o), i)
# Base.length(o::Config) = length(dict_subset(o))
# Base.keys(o::Config) = keys(dict_subset(o))
# Base.values(o::Config) = values(dict_subset(o))

# function Base.summary(io::IO, o::Config)
#     isdef(o) ?
#         print(io, styled"{bright_green:Config($(prefix(o)))} with $(length(o)) entries") :
#         print(io, styled"{bright_yellow:Undefined Config($(prefix(o)))}")
# end

# function Config(prefix = Key(), ref = nothing; kw...)
#     out = Config(OrderedDict{Key, Any}(), prefix, ref)
#     for (k, v) in kw
#         out[k] = v
#     end
#     return out
# end

# function Base.setindex!(o::Config, v, k::Key)
#     iskey(ref(o), k) || return key_error(ref(o), k)
#     isval(ref(o), k, v) || return val_error(ref(o), k, v)
#     dict(o)[k] = v
# end
# Base.setindex!(o::Config, v, k::KeyType) = setindex!(o, v, prefix(o) * Key(k))


# function Base.getindex(o::Config, k::Key)
#     iskey(ref(o), k) || return key_error(ref(o), k)
#     return get(dict(o), k, Undefined())
# end
# Base.getindex(o::Config, k::KeyType) = getindex(o, prefix(o) * Key(k))

# indexing by Key: Always absolute path
# Indexing by Symbol: Relative to prefix
# Indexing by String:


# is_prefix(prefix, o::Key) = is_prefix(Key(prefix), o)
# is_prefix(prefix::Key, o::Key) = prefix.sep == o.sep && prefix.parts == o.parts[1:length(prefix.parts)]

#-----------------------------------------------------------------------------# getters
# for f in (:dict, :prefix, :ref, :isd)

# dict(o)     = getfield(o, :dict)
# prefix(o)   = getfield(o, :prefix)
# ref(o)      = getfield(o, :ref)
# isdef(o) = getfield(o, :isdef)

# #-----------------------------------------------------------------------------# Config
# struct Config{R} <: AbstractDict{Symbol, Any}
#     dict::OrderedDict{Key, Any}
#     prefix::Key
#     ref::R
#     isdef::Bool
# end
# for f in fieldnames(Config)
#     @eval $f(o::Config) = getfield(o, $(QuoteNode(f)))
# end

# function Config(prefix = Key(), ref = nothing; kw...)
#     out = Config(OrderedDict{Key, Any}(), prefix, ref, true)
#     for (k, v) in kw
#         out[Key(k)] = v
#     end
#     return out
# end
# function (o::Config{T})(x::Pair...; kw...) where {T}
#     for (k, v) in Iterators.flatten((x, kw))
#         o[k] = v
#     end
#     return o
# end


# _undef(o::Config, k) = Config(dict(o), prefix(o) * k, ref(o), false)

# function Base.keys(o::Config)
#     dict_keys = collect(keys(dict(o)))
#     pre = prefix(o)
#     out = filter(x -> isprefix(pre), dict_keys)
#     map(out) do path
#         path.parts[length(pre) + 1:end]
#     end
# end
# Base.iterate(o::Config, i = 1) = i > length(o) ? nothing : (keys(o)[i], i + 1)

# # for f in (:keys, :values, :iterate, :length)
# #     @eval Base.$f(o::Config, x...) = $f(dict(o), x...)
# # end
# Base.merge!(a::Config, b::Config) = (merge!(dict(a), dict(b)); a)
# for f in (:empty!, :delete!)
#     @eval Base.$f(o::Config{T}, x...) where {T} = ($f(dict(o), x...); o)
# end

# # function Base.keys(o::Config)
# #     out = collect(keys(dict(o)))
# #     paths = filter!(x -> is_prefix(prefix(o), x), out)
# #     [first(x) for x]
# # # end
# # Base.length(o::Config) = length(keys(o))
# # function Base.iterate(o::Config, i::Int=1)
# #     i > length(o) && return nothing
# #     key = keys(o)[i]
# #     return (key => o[key], i + 1)
# # end

# # function Base.keys(o::Config)
# #     out = collect(keys(dict(o)))
# #     isnothing(prefix(o)) ? out : map(x -> replace(x, string(prefix(o), sep(o)) => ""), out)
# # end

# # function Base.getindex(o::Config, k::Key)
# #     iskey(ref(o), k) ? get(dict(o), k, _undef(o, k)) : key_error(ref(o), k)
# # end
# # Base.getindex(o::Config, k::KeyType) = getindex(o, prefix(o) * k)


# function Base.setindex!(o::Config, v, path::Key)
#     k = prefix(o) * path
#     iskey(ref(o), k) || return key_error(ref(o), k)
#     isval(ref(o), k, v) || return val_error(ref(o), k, v)
#     dict(o)[k] = v
# end
# # Base.setindex!(o::Config, v, k::KeyType) = setindex!(o, v, prefix(o) * k)

# # function Base.getindex(o::Config, _k::KeyType)
# #     k = Key(o, _k)
# #     iskey(ref(o), k) || key_error(ref(o), k)
# #     kys = filter(x -> is_prefix(k, x), keys(o))
# #     length(kys) == 0 && return Undefined(o, k)
# #     length(kys) == 1 && k == only(kys) && return dict(o)[k]
# #     return Config(filter(kv -> startswith(kv[1], k), dict(o)), k, sep(o), ref(o))
# # end
# # Base.haskey(o::Config, k::KeyType) = any(startswith(key(o, k), keys(o)))






# struct Config{T, D <: AbstractDict{Symbol, T}, S} <: AbstractDict{Symbol, Union{T,S}}
#     dict::OrderedDict{Symbol, T}
#     default::S
# end
# dict(o) = getfield(o, :dict)

# # Config(x::Pair...; kw...) = Config(OrderedDict{Symbol,Any}((Symbol(x[1]) => x[2] for x in x)..., pairs(kw)...))

# # Functions that map to the wrapped dict
# for f in (:keys, :values, :iterate, :length, :setindex!)
#     @eval Base.$f(o::Config, x...) = $f(dict(o), x...)
# end

# # Functions that map to the wrapped dict but return the Config
# for f in (:empty!, :merge!, :delete!)
#     @eval Base.$f(o::Config, x...) = ($f(dict(o), x...); o)
# end

# Base.propertynames(o::Config) = keys(o)
# Base.getproperty(o::Config, k::Symbol) = o[k]
# Base.setproperty!(o::Config, k::Symbol, v) = setindex!(o, v, k)

# OrderedCollections.freeze(o::Config) = Config(OrderedCollections.freeze(dict(o)))

# _config_value(x) = x
# _config_value(x::AbstractDict) = Config(x)
# _config_value(x::Pair) = Config(Symbol(x[1]) => x[2])
# _config_value(x::AbstractArray) = map(_config_value, x)

# OrderedCollections.isordered(::Type{Config}) = true

# delete_empty!(x) = x
# function delete_empty!(o::Config)
#     for (k,v) in pairs(o)
#         v isa Config && isempty(v) ? delete!(o, k) : delete_empty!(v)
#     end
#     o
# end

# dict(o::Config) = getfield(o, :d)

# StructTypes.StructType(::Type{Config}) = StructTypes.DictType()

# Base.getproperty(o::Config, k::Symbol) = get!(o, k, Config())
# Base.getproperty(o::Config, k) = getproperty(o, Symbol(k))

# Base.setproperty!(o::Config, k::Symbol, v) = dict(o)[Symbol(k)] = v
# Base.setproperty!(o::Config, k, v) = setproperty!(o, Symbol(k), v)

# Base.propertynames(o::Config) = collect(keys(dict(o)))

# Base.getindex(o::Config, k) = getproperty(o, Symbol(k))
# Base.setindex!(o::Config, v, k) = setproperty!(o, Symbol(k), v)

# Base.iterate(o::Config, args...) = iterate(dict(o), args...)
# Base.keys(o::Config) = keys(dict(o))
# Base.values(o::Config) = values(dict(o))
# Base.length(o::Config) = length(dict(o))
# Base.isempty(o::Config) = isempty(dict(delete_empty!(o)))
# Base.pairs(o::Config) = pairs(dict(o))
# Base.empty!(o::Config) = (empty!(dict(o)); o)
# Base.get(o::Config, k, default) = get(dict(o), Symbol(k), default)
# Base.get!(o::Config, k, default) = get!(dict(o), Symbol(k), default)
# Base.haskey(o::Config, k) = haskey(dict(o), Symbol(k))

# Base.delete!(o::Config, k) = (delete!(dict(o), Symbol(k)); o)

# Base.isequal(a::Config, b::Config) = dict(a) == dict(b)
# Base.copy(o::Config) = Config(copy(dict(o)))

# Base.merge(a::Config, b::Config) = Config(merge(dict(a), dict(b)))

# Base.merge!(a::Config, b::Config) = Config(merge!(dict(a), dict(b)))

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
