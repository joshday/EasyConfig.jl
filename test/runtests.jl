using EasyConfig
using OrderedCollections
using Test

@testset "Constructors" begin
    @test Config() == Config()
    @test isempty(Config())
    c = Config()
    c.x = 1
    @test Config(x=1) == Config(:x => 1) == Config("x" => 1) == Config(Dict(:x => 1)) == c
    @test Config(:x => 1; y=2) == Config(x=1, y=2)

    @testset "Wraps AbstractDict{Symbol, Any} without copying" begin
        d = Dict{Symbol, Any}(:x => 1)
        c = Config(d)
        c.y = 2
        @test d[:y] == 2
    end

    @testset "AbstractDict values become Configs" begin
        c = Config(Dict(:x => Dict(:y => Dict(:z => 1))))
        @test c.x isa Config
        @test c.x.y isa Config
        @test c.x.y.z == 1
        c.a = Dict(:b => 2)
        @test c.a isa Config
        @test c.a.b == 2
    end

    @testset "Config{D}" begin
        D = OrderedDict{Symbol, Any}
        @test Config{D}() isa Config{D}
        c = Config{D}(Dict(:x => 1))
        @test c isa Config{D}
        @test c.x == 1
    end
end

@testset "Get/set" begin
    c = Config()
    c.x = 1
    c[:y] = 2
    c["z"] = 3
    @test c.x == c[:x] == c["x"] == 1
    @test c.y == 2
    @test c.z == 3
    @test sort(collect(propertynames(c))) == [:x, :y, :z]

    @testset "Missing keys are Undefined" begin
        c = Config()
        @test c.x isa EasyConfig.Undefined
        @test c.x.y.z isa EasyConfig.Undefined
        @test isempty(c)
    end

    @testset "Nested assignment" begin
        c = Config()
        c.a.b.c.d = 1
        @test c.a.b.c.d == 1
        c.a.b.e = 2
        @test c.a.b.e == 2
        @test c.a.b.c.d == 1
        c[:f][:g] = 3
        @test c.f.g == 3
    end

    @testset "Nested assignment preserves dict type" begin
        c = Config(OrderedDict{Symbol, Any}())
        c.b.c = 1
        c.a = 2
        @test c.b isa Config{OrderedDict{Symbol, Any}}
        @test collect(keys(c)) == [:b, :a]
    end
end

@testset "AbstractDict interface" begin
    c = Config(x=1, y=2)
    @test length(c) == 2
    @test get(c, :x, 0) == 1
    @test get(c, "x", 0) == 1
    @test get(c, :nope, 0) == 0
    @test haskey(c, :x)
    @test !haskey(c, :nope)
    @test Dict(c) == Dict(:x => 1, :y => 2)

    @test delete!(c, :x) === c
    @test !haskey(c, :x)
    delete!(c, "y")
    @test isempty(c)

    c = Config(x=1)
    @test empty!(c) === c
    @test isempty(c)

    a = Config(x=1)
    b = copy(a)
    @test a == b
    b.x = 2
    @test a.x == 1
end

@testset "merge/merge!" begin
    a = Config(x=1)
    b = Config(y=Config(z=2))
    c = merge(a, b)
    @test c == Config(x=1, y=Config(z=2))
    @test a == Config(x=1)  # https://github.com/JuliaComputing/EasyConfig.jl/issues/8

    merge!(a, b)
    @test a == Config(x=1, y=Config(z=2))

    a = Config(x=1, y=Config(x=1))
    b = Config(x=5, y=Config(x=5, z="hi"))
    merge!(a, b)
    @test a.x == 5
    @test a.y.x == 5
    @test a.y.z == "hi"
end

@testset "show" begin
    @test repr(Config()) == "Config()"
    @test repr(Config(x=1)) == "Config(:x => 1)"
    @test repr(Config(x=Config(y="two"))) == "Config(:x => Config(:y => \"two\"))"
end

@testset "@config" begin
    val = 5
    c = @config (x.a=1, x.b=2, x.c.d.e.f.g=3, z=val)
    @test c.x.a == 1
    @test c.x.b == 2
    @test c.x.c.d.e.f.g == 3
    @test c.z == val

    c2 = @config x.a=1 x.b=2 x.c.d.e.f.g=3 z=val

    c3 = @config begin
        x.a = 1
        x.b = 2
        x.c.d.e.f.g = 3
        z = val
    end

    c4 = Config()
    c4.x.a = 1
    c4.x.b = 2
    c4.x.c.d.e.f.g = 3
    c4.z = val

    @test c == c2 == c3 == c4

    @test @config(x=1) == Config(x=1)
    @test @config((x=1,)) == Config(x=1)
    @test @config(begin end) == Config()

    # hygiene: macro's internal variable doesn't leak or clash
    config = 10
    @test @config(x=config).x == 10

    @test_throws Exception @eval @config x + 1
    @test_throws Exception @eval @config x[1] = 1
end
