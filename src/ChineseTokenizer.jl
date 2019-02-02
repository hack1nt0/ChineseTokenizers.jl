abstract type AbstractChineseTokenizer end

struct Gram1Tokenizer <: AbstractChineseTokenizer
    aca::AhoCorasickAutomaton{UInt32}
    nlf::Vector{Float64}
    INF::Float64
end

function Gram1Tokenizer(words::Vector{String}, freqs::Vector{Int})
    aca = AhoCorasickAutomaton{UInt32}(words)
    nlf = -log.(freqs ./ Float64(sum(freqs)))
    INF = maximum(nlf)
    return Gram1Tokenizer(aca, nlf, INF)
end

function Gram1Tokenizer(;filepath::String = joinpath(Pkg.dir("ChineseTokenizers"), "data", "dict"))
    words = String[]
    freqs = Int[]
    open(filepath, "r") do io
        for line in eachline(io)
            cells = split(line, " ")
            push!(words, String(cells[1]))
            push!(freqs, parse(Int, cells[2]))
        end
    end
    return Gram1Tokenizer(words, freqs)
end


function split(text::AbstractString, tokenizer::Gram1Tokenizer)::Vector{String}
    codes = codeunits(text)
    res = String[]
    aca = tokenizer.aca; nlf = tokenizer.nlf; INF = tokenizer.INF
    positions = reverse!(eachmatch(aca, text))
    @show sort(positions)
    if (length(positions) == 0) return [String(text)] end
    n = length(codes)
    dp = fill(INF, n + 1); dp = cumsum(dp); reverse!(dp)
    to = collect(1:n)
    for pos in positions
        if dp[pos.t + 1] + nlf[pos.i] < dp[pos.s]
            dp[pos.s] = dp[pos.t + 1] + nlf[pos.i]
            to[pos.s] = pos.t
        end
    end
    println("dp: ", dp)
    println("to: ", to)
    s = 1
    while s <= n
        t = to[s]
        if t == s
            t += 1
            while t <= n && t == to[t] t += 1 end
            t -= 1
        end
        push!(res, String(codes[s:t]))
        s = t + 1
    end
    return res
end
