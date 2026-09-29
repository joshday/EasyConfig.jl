[![Build status](https://github.com/JuliaComputing/EasyConfig.jl/workflows/CI/badge.svg)](https://github.com/JuliaComputing/EasyConfig.jl/actions?query=workflow%3ACI+branch%3Amaster)
[![deps](https://juliahub.com/docs/EasyConfig/deps.svg)](https://juliahub.com/ui/Packages/EasyConfig/tMFix?t=2)
[![version](https://juliahub.com/docs/EasyConfig/version.svg)](https://juliahub.com/ui/Packages/EasyConfig/tMFix)
[![pkgeval](https://juliahub.com/docs/EasyConfig/pkgeval.svg)](https://juliahub.com/ui/Packages/EasyConfig/tMFix)


<h1 align="center">EasyConfig</h1>

- **EasyConfig** provides a friendly-syntax, nested `AbstractDict{Symbol, Any}` data structure.
- The advantages over other `AbstractDict/NamedTuple`s are:

## 1) Intermediate levels are created on the fly:

- This is quite convenient for working with JSON specs (e.g. [PlotlyLight.jl](https://github.com/JuliaComputing/PlotlyLight.jl)).


```julia
c = Config()
c.one.two.three = 1
```

<br>

- Compare this to `OrderedDict` and `NamedTuple`:

```julia
c = OrderedDict(:one => OrderedDict(:two => OrderedDict(:three => 1)))

c = (one = (two = (three = 1,),),)

c = (; one = (;two = (;three = 1)))
```

<br><br>

## 2) Easy to Use Both Interactively and Programmatically

- You can use any combination of `String`/`Symbol` with `getproperty`/`getindex`.
- For working *interactively*, `getproperty` is the most convenient to work with.
- For working *programmatically*, `getindex` is the most convenient to work with.

```julia
# getproperty
c.one.two.three

# getindex
c[:one][:two][:three]

# mix and match
c["one"].two."three"
```

<br><br>

# `@config`

Create a `Config` with a NamedTuple-like or block syntax. The following examples create equivalent `Config`s:

```julia
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
```

# Note

- Accessing a non-existent property creates an `Undefined`.  
- This is necessary for assigning deeply nested properties (an eventual `setindex!` after nested `getindex`-es).
  - `config.a == Undefined(config, [:a])`, `config.a.b == Undefined(config, [:a, :b])`, etc.
  - `config.a.b.c = 1` == `Undefined(config, [:a, :b])[:c] = 1`
