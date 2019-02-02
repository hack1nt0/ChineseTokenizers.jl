using SparseArrays
using AhoCorasickAutomatons

struct PosTokenizer{Tv, Ti}
    aca::AhoCorasickAutomaton{Ti}
    # dict::Vector{String}
    pos::Vector{String}
    hpr::Vector{Tv}
    h2h::Matrix{Tv}
    # h2v::SparseMatrixCSC{Tv, Ti}
    alpha::Vector{Tv}
    # toth::Vector{Tv}
    h2v::Vector{Dict{Ti, Tv}}
end

function PosTokenizer{Tv, Ti}(dictpath::String, pospath::String) where Tv where Ti
    dict = Dict{String, Int}()
    open(dictpath, "r") do io
        for line in eachline(io)
            cells = split(line, " ")
            word = String(cells[1])
            if !haskey(dict, word)
                dict[word] = length(dict) + 1
            end
        end
    end
    poss = Dict{String, Int}()
    hpr = Tv[]
    h2h = Dict{Ti, Tv}[]
    h2v = Dict{Ti, Tv}[]
    open(pospath, "r") do io
        for line in eachline(io)
            nword = parse(Int, line)
            if nword == 0 continue end
            ipos = ipos2 = iword = 0
            for line2 in eachline(io)
                cells = split(line2)
                pos2 = String(split(cells[1], "-")[1])
                word = String(cells[2])
                if !haskey(poss, pos2)
                    ipos2 = length(poss) + 1
                    poss[pos2] = ipos2
                else
                    ipos2 = poss[pos2]
                end
                if !haskey(dict, word)
                    iword = length(dict) + 1
                    dict[word] = iword
                else
                    iword = dict[word]
                end
                if ipos == 0
                    ipos2 = poss[pos2]
                    # if !haskey(hpr, ipos2) hpr[ipos2] = 0 end
                    while ipos2 > length(hpr) push!(hpr, 0) end
                    hpr[ipos2] += 1
                end
                if ipos != 0
                    # if !haskey(h2h, ipos) h2h[ipos] = Dict{Int, Int}() end
                    # if !haskey(h2h[ipos], ipos2) h2h[ipos][ipos2] = 0 end
                    while ipos > length(h2h) push!(h2h, Dict{Ti, Tv}()) end
                    if !haskey(h2h[ipos], ipos2) h2h[ipos][ipos2] = 0 end
                    h2h[ipos][ipos2] += 1
                end
                # if !haskey(v2h, iword) v2h[iword] = Dict{Int, Int}() end
                # if !haskey(v2h[iword], ipos2) v2h[iword][ipos2] = 0 end
                # v2h[iword][ipos2] += 1
                while ipos2 > length(h2v) push!(h2v, Dict{Ti, Tv}()) end
                if !haskey(h2v[ipos2], iword) h2v[ipos2][iword] = 0 end
                h2v[ipos2][iword] += 1
                ipos = ipos2
                nword -= 1
                if nword == 0 break end
            end
        end
    end
    nword = length(dict)
    dict2 = Vector{String}(undef, nword)
    for (w, i) in dict dict2[i] = w end
    aca = AhoCorasickAutomaton{Ti}(dict2; sort = true)
    npos = length(poss);
    pos = Vector{String}(undef, npos)
    for (p, i) in poss pos[i] = p end
    # hpr2 = ones(Tv, npos)
    # for (ip, cnt) in hpr hpr2[ip] += cnt end
    hpr .+= 1
    tothpr = sum(hpr)
    @assert !isinf(tothpr)
    hpr .= -log.(hpr ./ tothpr) # add prior?
    h2h2 = zeros(Tv, npos, npos)
    for (ih, hs) in enumerate(h2h)
        for (ih2, cnt) in hs
            h2h2[ih2, ih] += cnt
        end
    end

    # nzeroinds = findall(!iszero, h2h2)
    # zeroinds = findall(iszero, h2h2)
    # println(zeroinds)
    h2h2 .= -log.(h2h2 ./ sum(h2h2; dims = 1))
    # h2h2[zeroinds] .= maximum(h2h2[nzeroinds]) + 1
    # nnz = sum(map(length, values(v2h)))
    # colptr = Vector{Ti}(undef, nword + 1); colptr[1] = Ti(1);
    # for i = 2:nword + 1
    #     colptr[i] = colptr[i - 1] + (haskey(v2h, i - 1) ? length(v2h[i - 1]) : 0)
    # end
    # rowval = Vector{Ti}(undef, nnz);
    # nzval = Vector{Tv}(undef, nnz);
    # toth = zeros(Tv, npos); rowlen = zeros(Tv, npos);
    # for i = 1:nword
    #     if colptr[i] == colptr[i + 1] continue end
    #     p = colptr[i]
    #     for j in sort!(collect(v2h[i]))
    #         rowval[p] = j[1]
    #         nzval[p] = j[2]
    #         p += 1
    #         toth[j[1]] += 1
    #         rowlen[j[1]] += 1
    #     end
    # end
    # h2v = SparseMatrixCSC(npos, nword, colptr, rowval, nzval)
    # alpha = ones(Tv, npos); alpha .= 1e-6; alpha[findfirst(isequal("NN"), pos)] = 1;
    # toth .+= rowlen .+ 1 * alpha
    # return PosTokenizer(aca, pos, hpr2, h2h2, h2v, alpha, toth)
    alpha = ones(Tv, npos);
    # alpha .= 1e-6;
    # alpha[findfirst(isequal("NN"), pos)] = 1;
    ma = 0.0
    for (ih, vs) in enumerate(h2v)
        # tot = sum(values(vs)) + (nword + 1) * alpha[ih]
        # for v in keys(vs) vs[v] = -log(vs[v] + alpha[ih]) + log(tot) end
        # alpha[ih] = -log(alpha[ih]) + log(tot)
        tot = sum(values(vs))
        for v in keys(vs)
            vs[v] = -log(vs[v]) + log(tot)
            ma = max(ma, vs[v])
        end
    end
    alpha .= ma + 2
    alpha[findfirst(isequal("NN"), pos)] = ma + 1
    return PosTokenizer(aca, pos, hpr, h2h2, alpha, h2v)
end

PosTokenizer(dictpath::String, pospath::String) = PosTokenizer{Float32, UInt32}(dictpath, pospath)

function h2v(obj::PosTokenizer{Tv, Ti}, h::String, v::String) where Tv where Ti
    ih = findfirst(isequal(h), obj.pos)
    iv = get(obj.aca, v, Ti(0))
    return get(obj.h2v[ih], iv, obj.alpha[ih])
end

function h2h(obj::PosTokenizer{Tv, Ti}, pos1::String, pos2::String) where Tv where Ti
    i1 = findfirst(isequal(pos1), obj.pos)
    i2 = findfirst(isequal(pos2), obj.pos)
    return obj.h2h[i2, i1]
end

import Base.display
using Markdown
function display(obj::PosTokenizer{Tv, Ti}) where Tv where Ti
    rows = Any[["type", typeof(obj)],
                ["npos", length(obj.pos)],
                ["nword", size(obj.h2v, 2)],
                ["size", Base.format_bytes(Base.summarysize(obj))]
    ];
    return display(Markdown.MD(Markdown.Table(rows, Symbol[:l, :r])))
end

# function h2v(obj::PosTokenizer{Tv, Ti}, h, v) where Tv where Ti
#     return -log((obj.h2v[h, v] + obj.alpha[h]) / obj.toth[h])
# end

import Base: read, write, split

# function read(io::IO, ::Type{PosTokenizer})
#     npos = read(io, Int)
#     nword = read(io, Int)
#     nnz = read(io, Int)
#     Ti = [UInt32, UInt64][read(io, Int) / 4]
#     Tv = [Float32, Float64][read(io, Int) / 4]
#     dict = String[];
#     pos = map(String, split(readline(io)))
#     @assert length(pos) == npos
#     for line in eachline(io)
#         cells = split(line, " ")
#         push!(dict, String(cells[1]))
#     end
#     @assert length(dict) == nword
#     resize!(dict, length(dict))
#     aca = AhoCorasickAutomaton{Ti}(words)
#     hpr = reinterpret(Tv, read(io, npos * sizof(Tv)))
#     h2h = reshape(reinterpret(Tv, read(io, npos * npos * sizof(Tv))), (npos, npos))
#     colptr = reinterpret(Tv, read(io, (nword + 1) * sizof(Tv)))
#     rowval = reinterpret(Ti, read(io, nnz * sizof(Ti)))
#     nzval = reinterpret(Tv, read(io, nnz * sizof(Tv)))
#     h2v = SparseMatrixCSC{Tv, Ti}(npos, nword, colptr, rowval, nzval)
#     NN2V = Tv(0);
#     return PosTokenizer(aca, dict, pos, hpr, h2h, h2v, NN2V)
# end

function whichmin(xs)
    res = 1
    for i = 2:length(xs)
        if xs[res] > xs[i]
            res = i
        end
    end
    return res
end

function split(text::AbstractString, obj::PosTokenizer; pos = true)
    codes = codeunits(text)
    aca = obj.aca; pos = obj.pos;
    hpr = obj.hpr; h2h = obj.h2h;
    alpha = obj.alpha; h2v = obj.h2v;
    positions = collect(eachmatch(aca, text))
    if (length(positions) == 0) return [String(text)] end
    ncode = length(codes); npos = length(pos);
    dp = Matrix{Float64}(undef, npos, ncode + 1); dp .= 1.0 / 0.0; dp[:, ncode + 1] .= 0;
    nx = Matrix{Tuple{Int, Int}}(undef, npos, ncode + 1)
    j = length(positions)
    charindexes = collect(eachindex(text)); push!(charindexes, ncode + 1);
    k = nchar = length(charindexes) - 1
    for i = ncode:-1:1
        while j > 0 && i < positions[j].t j -= 1 end
        while j > 0 && i == positions[j].t
            iword = positions[j].i
            s = positions[j].s
            t = positions[j].t
            # println(String(codes[s:t]))
            for ipos = 1:npos
                res = dp[ipos, s]
                H2V = get(h2v[ipos], iword, alpha[ipos])
                nxt = nx[ipos, s]
                for ipos2 = 1:npos
                    cur = H2V + h2h[ipos2, ipos] + dp[ipos2, t + 1]
                    if cur < res
                        res = cur
                        nxt = (ipos2, t)
                    end
                end
                dp[ipos, s] = res
                nx[ipos, s] = nxt
            end
            j -= 1
        end
        if i == charindexes[k]
            iword = 0
            s = i
            t = charindexes[k + 1] - 1
            for ipos = 1:npos
                res = dp[ipos, s]
                H2V = get(h2v[ipos], iword, alpha[ipos])
                nxt = nx[ipos, s]
                for ipos2 = 1:npos
                    cur = H2V + h2h[ipos2, ipos] + dp[ipos2, t + 1]
                    if cur < res
                        res = cur
                        nxt = (ipos2, t)
                    end
                end
                dp[ipos, s] = res
                nx[ipos, s] = nxt
            end
            k -= 1
        end
    end
    # @show dp
    # @show nx
    # @show positions
    # inn = findfirst(isequal("NN"), pos)
    # NN2V = alpha[inn] / toth[inn]
    @show
    dp[:, 1] .+= hpr
    ipos = whichmin(dp[:, 1])
    pvis = 1
    res = Vector{Tuple{String, String}}()
    while pvis <= ncode
        # @show nx[ipos, pvis]
        nxt = nx[ipos, pvis]
        ipos2 = nxt[1]
        pvis2 = nxt[2]
        push!(res, (pos[ipos], String(codes[pvis:pvis2])))
        ipos = ipos2
        pvis = pvis2 + 1
    end
    return (res = res, dp = dp, segs = map(x -> String(codes[x.s:x.t]), positions))
end
