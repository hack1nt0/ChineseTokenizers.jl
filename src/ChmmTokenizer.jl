struct ChmmTokenizer{Tv <: AbstractFloat, Ti <: Unsigned}
    nword::Int
    aca::AhoCorasickAutomaton{Ti}
    pos::Vector{String}
    hpr::Vector{Tv}
    h2h::Matrix{Tv}
    h2v::Vector{Dict{Int, Tv}}
    alpha::Vector{Tv}
end

function ==(a::ChmmTokenizer{Tv, Ti}, b::ChmmTokenizer{Tv, Ti}) where {Tv, Ti}
    res = true
    for fname in fieldnames(ChmmTokenizer{Tv, Ti})
        res &= getfield(a, fname) == getfield(b, fname)
    end
    return res
end

function write(io::IO, obj::ChmmTokenizer{Tv, Ti}) where {Tv, Ti}
    nbit = 0
    nbit += write(io, obj.nword)
    nbit += write(io, sizeof(Tv))
    nbit += write(io, sizeof(Ti))
    nbit += write(io, obj.aca)
    for p in obj.pos
        nbit += write(io, p, " ")
    end
    nbit += write(io, "\n")
    nbit += write(io, obj.hpr)
    nbit += write(io, obj.h2h)
    for vp in obj.h2v
        nbit += write(io, length(vp))
        for (v, p) in vp
            nbit += write(io, v)
            nbit += write(io, p)
        end
    end
    nbit += write(io, obj.alpha)
    return nbit
end

function nbit2type(nbit, types)
    filter(x -> sizeof(x) == nbit, types)[1]
end

function read(io::IO, obj::Type{ChmmTokenizer})
    nword = read(io, Int)
    Tv = nbit2type(read(io, Int), [Float32, Float64])
    Ti = nbit2type(read(io, Int), [UInt8, UInt16, UInt32, UInt64])
    aca = read(io, AhoCorasickAutomaton)
    pos = split(readline(io))
    npos = length(pos)
    hpr = reinterpret(Tv, read(io, npos * sizeof(Tv)))
    h2h = reshape(reinterpret(Tv, read(io, npos * npos * sizeof(Tv))), (npos, npos))
    h2v = Vector{Dict{Int, Tv}}(undef, npos)
    for i = 1:npos
        vps = Dict{Int, Tv}()
        nv = read(io, Int)
        for j = 1:nv
            v = read(io, Int)
            p = read(io, Tv)
            vps[v] = p
        end
        h2v[i] = vps
    end
    alpha = reinterpret(Tv, read(io, npos * sizeof(Tv)))
    return ChmmTokenizer{Tv, Ti}(nword, aca, pos, hpr, h2h, h2v, alpha)
end

function ChmmTokenizer{Tv}(poswords::String, userdict::String) where Tv
    dict = Dict{String, Int}()
    open(userdict, "r") do io
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
    h2h = Dict{Int, Tv}[]
    h2v = Dict{Int, Tv}[]
    open(poswords, "r") do io
        for line in eachline(io)
            nword = parse(Int, line)
            if nword == 0 continue end
            poswords = Vector{Tuple{String, String}}()
            tmp = nword
            for line2 in eachline(io)
                cells = split(line2)
                pos  = String(split(cells[1], "-")[1])
                word = String(cells[2])
                push!(poswords, (pos, word))
                tmp -= 1
                if tmp == 0 break end
            end
            # hpr, h2h, h2v
            for i = 1:nword
                pos  = poswords[i][1]
                word = poswords[i][2]
                ih = get(poss, pos, length(poss) + 1)
                if ih == length(poss) + 1
                    poss[pos] = ih
                    push!(hpr, 0)
                    push!(h2h, Dict{Int, Tv}())
                    push!(h2v, Dict{Int, Tv}())
                end
                iw = get(dict, word, length(dict) + 1)
                if iw == length(dict) + 1
                    dict[word] = iw
                end
                if i == 1 hpr[ih] += 1 end
                if i > 1
                    ph = poss[poswords[i - 1][1]]
                    if !haskey(h2h[ph], ih) h2h[ph][ih] = 0 end
                    h2h[ph][ih] += 1
                end
                if !haskey(h2v[ih], iw) h2v[ih][iw] = 0 end
                h2v[ih][iw] += 1
            end
        end
    end
    nword = length(dict)
    dict2 = Vector{String}(undef, nword)
    for (w, i) in dict dict2[i] = w end
    Ti = filter(x -> nword <= typemax(x), [UInt8, UInt16, UInt32, UInt64])[1]
    aca = AhoCorasickAutomaton{Ti}(dict2; sort = true)
    npos = length(poss);
    pos = Vector{String}(undef, npos)
    for (p, i) in poss pos[i] = p end
    hpr .+= 1
    tothpr = sum(hpr)
    @assert !isinf(tothpr)
    hpr .= -log.(hpr ./ tothpr)
    h2h2 = zeros(Tv, npos, npos)
    for (ih, hs) in enumerate(h2h)
        for (ih2, cnt) in hs
            h2h2[ih2, ih] += cnt
        end
    end
    h2h2 .= -log.(h2h2 ./ sum(h2h2; dims = 1))
    alpha = ones(Tv, npos);
    ma = 0.0
    for (ih, vs) in enumerate(h2v)
        tot = sum(values(vs))
        for v in keys(vs)
            vs[v] = -log(vs[v]) + log(tot)
            ma = max(ma, vs[v])
        end
    end
    alpha .= ma * 100
    return ChmmTokenizer{Tv, Ti}(nword, aca, pos, hpr, h2h2, h2v, alpha)
end

function ChmmTokenizer()
    defaultmodel = joinpath(dirname(pathof(ChmmTokenizers)), "..", "chmm")
    open(defaultmodel, "r") do io
        read(io, ChmmTokenizer)
    end
end

function chmm()
    poswords = joinpath(dirname(pathof(ChmmTokenizers)), "..", "data", "posword")
    userdict = joinpath(dirname(pathof(ChmmTokenizers)), "..", "data", "userdict")
    return ChmmTokenizer{Float32}(poswords, userdict)
end

function h2v(obj::ChmmTokenizer{Tv, Ti}, h::String, v::String) where Tv where Ti
    ih = findfirst(isequal(h), obj.pos)
    iv = get(obj.aca, v, Ti(0))
    return get(obj.h2v[ih], iv, obj.alpha[ih])
end

function h2h(obj::ChmmTokenizer{Tv, Ti}, pos1::String, pos2::String) where Tv where Ti
    i1 = findfirst(isequal(pos1), obj.pos)
    i2 = findfirst(isequal(pos2), obj.pos)
    return obj.h2h[i2, i1]
end

function display(obj::ChmmTokenizer{Tv, Ti}) where Tv where Ti
    rows = Any[["name", "count"],
                ["byte", Base.format_bytes(Base.summarysize(obj))],
                ["word", obj.nword],
                ["POS", length(obj.pos)]];
    for i = 1:length(obj.pos)
        push!(rows, [obj.pos[i], length(obj.h2v[i])])
    end
    return display(Markdown.MD(Markdown.Table(rows, Symbol[:l, :r])))
end

function split(text::AbstractString, obj::ChmmTokenizer{Tv, Ti}) where {Tv, Ti}
    codes = codeunits(text)
    aca = obj.aca; pos = obj.pos;
    hpr = obj.hpr; h2h = obj.h2h;
    alpha = obj.alpha; h2v = obj.h2v;
    matches = collect(eachmatch(aca, text))
    sort!(matches)
    nm = length(matches)
    nc = length(codes)
    nh = length(pos)
    dp = fill(Tv(Inf), nh, nc)
    bk = fill((0, 0), nh, nc)
    cover = fill(false, nc)
    for m in matches cover[m.s:m.t] .= true end
    pm = 1
    sc = 1
    while sc <= nc
        if !cover[sc]
            tc = sc + 1
            while tc <= nc && !cover[tc] tc += 1 end
            tc -= 1
            for sh in 1:nh
                for th in 1:nh
                    cur = (sc == 1 ? hpr[sh] : dp[sh, sc - 1]) + h2h[th, sh] + get(h2v[th], 0, alpha[th])
                    if cur < dp[th, tc]
                        dp[th, tc] = cur
                        bk[th, tc] = (-sh, sc - 1)
                    end
                end
            end
            sc = tc + 1
        else
            while pm <= nm && matches[pm].s < sc pm += 1 end
            while pm <= nm && matches[pm].s == sc
                m = matches[pm]
                tc = m.t
                iw = m.i
                for sh in 1:nh
                    for th in 1:nh
                        cur = (sc == 1 ? hpr[sh] : dp[sh, sc - 1]) + h2h[th, sh] + get(h2v[th], iw, alpha[th])
                        if cur < dp[th, tc]
                            dp[th, tc] = cur
                            bk[th, tc] = (sh, sc - 1)
                        end
                    end
                end
                pm += 1
            end
            sc += 1
        end
    end
    segs = Tuple{String, String}[]
    th = findmin(dp[:, nc])[2]
    tc = nc
    while 1 <= tc
        sh = bk[th, tc][1]
        sc = bk[th, tc][2]
        if sh < 1
            sh = -sh
            push!(segs, (pos[th] * "?", String(codes[sc + 1:tc])))
        else
            push!(segs, (pos[th], String(codes[sc + 1:tc])))
        end
        th = sh
        tc = sc
    end
    reverse!(segs)
    # return (res = segs, dp = dp, segs = map(x -> String(codes[x.s:x.t]), matches))
    return segs
end
