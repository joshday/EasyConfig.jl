using EasyConfig
using Test

@testset "Key" begin
    @test isempty(Key())
    @test Key() == Key()
    @test Key("x") == Key("x")
    @test Key("a.b.c") == Key("a.b.c")
    @test Key("a.b.c") != Key("a/b/c")
    @test Key("a").b == Key("a.b")
    @test Key("a") * Key("b") == Key("a.b")
    @test EasyConfig.strip_prefix(Key("a.b.c"), Key("a.b")) == Key("c")
    @test string(Key("a.b.c")) == "a.b.c"
    @test collect(Key("a.b.c")) == collect("a.b.c")
    @test Key("a").b.c.d.e == Key("a.b.c.d.e")
    @test EasyConfig.parent(Key("a.b.c")) == Key("a.b")
    @test Key("a.b.c") < Key("a.b.z")
end

@testset "KV" begin
    @test KV() == KV()
    @test KV("x" => 1)["x"] == 1
    # @test KV("x" => 1) == KV(:x => 1)
end

# @testset "Constructors" begin
#     @test Config() == Config()
#     c = Config()
#     c.x = 1
#     @test Config(x=1) == Config(:x => 1) == Config(Dict(:x => 1)) == Config((; x=1)) == c

#     @testset "AbstractDict values" begin
#         d = Dict(:x => Dict(:y => 1))
#         c = Config(d)
#         @test c.x isa Config
#     end

#     @testset "Vector{<:AbstractDict} values" begin
#         d = Dict(:x => [Dict(:y => 1), Dict(:y=> 2)])
#         c = Config(d)
#         @test c.x isa Vector{Config}
#     end

#     @testset "Pair values" begin
#         data = [Dict("x"=>1), "y" => 2]
#         c = Config(; data)
#         @test c.data[1].x == 1
#         @test c.data[2].y == 2
#     end
# end

# @testset "Set/get property/field" begin
#     c = Config()
#     c.one."two"["three"][:four] = 5
#     @test c.one.two.three.four == 5
#     c."test" == Config()
#     @test propertynames(c) == [:one, :test]
# end

# @testset "Other base methods" begin
#     c = Config()

#     @test get(c, "test", 1) == 1
#     @test c."test" == Config()

#     @test get!(c, "test2", 1) == 1
#     @test c."test2" == 1
#     delete!(c, "test")
#     @test propertynames(c) == [:test2]

#     @test keys(Config(x = 1)) == keys(OrderedDict(:x => 1))
#     @test all(values(Config(x = 1)) .== values(OrderedDict(:x => 1)))
#     @test pairs(Config(x = 1)) == pairs(OrderedDict(:x => 1))
#     @test empty!(Config(x=1)) == Config()
#     @test haskey(Config(x=1), "x") == haskey(Config(x=1), :x) == true

#     @test Config(x=1) == Config(:x => 1) == Config("x" => 1)

#     a = Config(x=1)
#     b = copy(a)
#     @test a !== b

#     c = merge(a, Config(x=2,y=3))
#     @test c.x == 2
#     @test c.y == 3

#     # https://github.com/JuliaComputing/EasyConfig.jl/issues/8
#     a = Config(x=1)
#     b = Config(y=Config(z=2))
#     c = merge(a, b)
#     @test a == Config(x=1)

#     merge!(a, b)
#     @test a == Config(x=1, y=Config(z=2))
# end

# @testset "from NamedTuple" begin
#     nt = (x=1, y=(x=1, y=(x=1, y=(x=1,y=2))))
#     c = Config(nt)
#     @test c.y.y.y.y == 2
# end

# @testset "from Dict" begin
#     d = Dict(:x => Dict(:x => Dict(:x => Dict(:x => 2))))
#     c = Config(d)
#     @test c.x.x.x.x == 2
# end

# @testset "merge!" begin
#     a = Config(x = 1, y = Config(x = 1))
#     b = Config(x = 5, y = Config(x=5, z="hi"))
#     c = merge(a, b)
#     merge!(a, b)
#     @test a == c
#     @test a.x == 5
#     @test a.y.x == 5
#     @test a.y.z == "hi"
# end

# @testset "isempty/delete_empty!" begin
#     c = Config()
#     c.x.x.x
#     @test isempty(c)
#     c.x.x.x
#     EasyConfig.delete_empty!(c)
#     @test isempty(c)
# end

# @testset "StructTypes" begin
#     @test isempty(StructTypes.keyvaluepairs(Config()))
#     c = Config(x=1,y=2)
#     @test StructTypes.keyvaluepairs(c)[:x] == 1
#     @test StructTypes.keyvaluepairs(c)[:y] == 2
# end

# @testset "@config" begin
#     val = 5
#     c = @config (x.a=1, x.b=2, x.c.d.e.f.g = 3, z = val)
#     @test c.x.a == 1
#     @test c.x.b == 2
#     @test c.x.c.d.e.f.g == 3
#     @test c.z == val

#     c2 = @config x.a=1 x.b=2 x.c.d.e.f.g=3 z=val

#     c3 = @config begin
#         x.a = 1
#         x.b = 2
#         x.c.d.e.f.g = 3
#         z = val
#     end

#     c4 = Config()
#     c4.x.a = 1
#     c4.x.b = 2
#     c4.x.c.d.e.f.g = 3
#     c4.z = val

#     @test c == c2 == c3
# end
