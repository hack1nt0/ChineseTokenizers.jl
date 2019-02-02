using Test, ChineseTokenizers, Pkg

@testset "Result of split is correct." begin
    filepath = joinpath(Pkg.dir("ChineseTokenizers"), "data", "dict")
    tokenizer = ChineseTokenizer(;filepath=filepath)
    text = "好好学习天天向上";
    res = split(text, tokenizer)
    @show res
    @test length(res) < length(text)
end

@testset "Read and write is correct." begin
    # filepath = joinpath(Pkg.dir("ChineseTokenizers"), "data", "dict")
    # keys = Vector{String}()
    # for i = 1:10
    #     key = Random.randstring("AB", rand(0:10))
    #     push!(keys, key)
    # end
    # obj = AhoCorasickAutomaton(keys)
    # io = IOBuffer()
    # nbytes = write(io, obj)
    # @test nbytes == sizeof(io.data)
    # seek(io, 0)
    # obj2 = read(io, AhoCorasickAutomaton)
    # @test obj == obj2
end
