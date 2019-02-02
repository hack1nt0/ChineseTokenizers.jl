import Base.convert
function convert(::Type{Vector{Char}}, s::String)
    cps = Vector{Char}(undef, length(s))
    for (i, cp) in enumerate(s)
        cps[i] = cp
    end
    return cps
end

abstract type AbstractChineseTree end
struct ChineseTree <: AbstractChineseTree
    adj::Vector{Vector{Int}}
    label::Vector{String}
end
ChineseTree() = ChineseTree(Vector{Vector{Int}}(), String[])

function ChineseTree(chars::Vector{Char})
    n = length(chars)
    obj = ChineseTree()
    nodes = maketree!(obj, findfirst(x -> x == '(', chars), chars, 1)
    return obj
end

function addedge!(obj::AbstractChineseTree, from::Int, to::Int)
    adj = obj.adj
    while length(adj) < to
        push!(adj, Int[])
    end
    push!(adj[from], to)
    return nothing
end

function setlabel!(obj::AbstractChineseTree, which::Int, text::AbstractString)
    label = obj.label
    if length(label) < which
        resize!(label, which)
    end
    label[which] = text
    return nothing
end

function leaves(obj::AbstractChineseTree)::Vector{Int}
    return filter(x -> length(obj.adj[x]) == 0, 1:length(obj.adj))
end

function text(obj::AbstractChineseTree)
    return join(filter(x -> !startswith(x, '*'), obj.label[leaves(obj)]))
end

struct ChineseBinaryTree
    adj::Vector{Tuple{Int, Int}}
    label::Vector{Int}
end

function ChineseBinaryTree(ct::ChineseTree)
end

function dfstraverse(tree::AbstractChineseTree, visitor::Function; cur::Int = 1)
    for chd in tree.adj[cur]
        dfstraverse(tree, visitor; cur = chd)
    end
    visitor(tree, cur)
    return nothing
end


function ChineseTree(ct::String)
    return ChineseTree(convert(Vector{Char}, ct))
end

function maketree!(obj, l::Int, chars::Vector{Char}, cur::Int)
    tot = 0
    l += 1
    r = l
    while chars[r] != '(' && chars[r] != ')' r += 1 end
    if (chars[r] == ')')
        ss = split(join(chars[l:r - 1]))
        @assert length(ss) == 2
        addedge!(obj, cur, cur + 1)
        setlabel!(obj, cur, ss[1])
        setlabel!(obj, cur + 1, ss[2])
        tot = 2
    else
        @assert chars[r] == '('
        ss = split(join(chars[l:r - 1]))
        # @assert length(ss) == 1 string(l, "  ", chars)
        if length(ss) == 0
            return maketree!(obj, r, chars, cur)
        end
        @assert length(ss) == 1
        setlabel!(obj, cur, ss[1])
        tot = 1
        nlb = 1
        while nlb > 0
            if (chars[r] == '(')
                if nlb == 1 l = r end
                nlb += 1
            elseif chars[r] == ')'
                nlb -= 1
                if nlb == 1
                    addedge!(obj, cur, cur + tot)
                    tot += maketree!(obj, l, chars, cur + tot)
                end
            end
            r += 1
        end
    end
    return tot
end

import Base.display
function display(obj::AbstractChineseTree)
    n = length(obj.label)
    @assert n > 1
    leafs = leaves(obj)
    @assert maximum(leafs) <= n
    H = length(leafs)
    height = fill(typemax(Int), n)
    width = fill(0, n)
    for (i, leaf) in enumerate(leafs)
        height[leaf] = i
        width[leaf] = 1
    end
    function visitor(tree, cur)
        if length(tree.adj[cur]) > 0
            for chd in tree.adj[cur]
                height[cur] = min(height[cur], height[chd])
                width[cur] = max(width[cur], width[chd] + 1)
            end
        end
    end
    dfstraverse(obj, visitor)
    W = maximum(width)
    width = W .- width .+ 1
    mat = Matrix{String}(undef, H, W)
    fill!(mat, "")
    for i = 1:n
        mat[height[i], width[i]] = obj.label[i]
    end
    function drawedge!(h, w, hh, ww)
        for i = h:hh - 1
            if mat[i, w] == ""
                mat[i, w] = "│"
            elseif mat[i, w] == "└"
                mat[i, w] = "├"
            end
        end
        if hh >= h
            mat[hh, w] = "└";
        end
        mat[hh, w + 1:ww] .= "─";
        return nothing
    end
    colors = Dict{String, Int}()
    function visitor2(tree, cur)
        if length(tree.adj[cur]) > 0
            c = tree.label[cur]
            if !haskey(colors, c)
                colors[c] = (1 + (length(colors) + 1) * 10) % 256
            end
            for chd in tree.adj[cur]
                drawedge!(height[cur] + 1, width[cur], height[chd], width[chd] - 1)
            end
        end
    end
    dfstraverse(obj, visitor2)
    maxwidth = mapreduce(length, max, mat; dims = 1) .+ 2
    for h = 1:H, w = 1:W
        c = mat[h, w]
        if w == W
            println(" ", c)
            continue
        end
        padl = div(maxwidth[w] - length(c), 2)
        if (w == W - 1)
            padl = maxwidth[w] - length(c)
        end
        padr = maxwidth[w] - length(c) - padl
        padlc = padrc = "─"
        if c == "" || c == "│"
            padlc = padrc = " "
        elseif c == "└" || c == "├" || h == 1 && w == 1
            padlc = " "
        end
        mat[h, w] = padlc ^ padl * c * padrc ^ padr
        for i = 1:padl print(padlc) end
        if haskey(colors, c)
            printstyled(c; color = colors[c])
        else
            print(c)
        end
        for i = 1:padr print(padrc) end
    end
    return nothing
end

xs =  """
( (IP (NP-TMP (NT 10月)
(NT 2号) )
(PU ，)
(NP-SBJ (-NONE- *pro*))
(VP (VE 有)
(IP-OBJ (NP-SBJ (NP (NN 患者) )
(CC 及)
(NP (NP (PN 其) )
(NP (NN 家属) ) ) )
(VP (VP (VP (VV 到)
(NP-OBJ-PN (NR 桐城市)
(NN 人民)
(NN 医院) ) )
(VP (VV 去)
(VP (VV 看病) ) ) )
(PU ，)
(VP (PP-PRP (P 因)
(IP (NP-SBJ (NN 护士)
(NN 嗓门) )
(VP (VA 大)
(ADVP (AD 些) ) ) ) )
(PU ，)
(ADVP (AD 便) )
(VP (VV 大打出手) ) )
(PU ，)
(VP (BA 将)
(IP-OBJ (NP-SBJ-1 (NP (DNP (NP (NN 医院) )
(DEG 的) )
(NP (NN 急诊科)
(NN 医生) ) )
(NP-PN (NR 杨辉) ) )
(VP (VP (ADVP (AD 狠) )
(VP (VV 揣)
(NP-OBJ (-NONE- *-1))) )
(PU ，)
(VP (VV 打成)
(NP-OBJ (NN 骨折) ) ) ) ) ) ) ) )
(PU 。) ) )
"""

obj = ChineseTree(xs)
display(obj)


mutable struct Block
    chars::Vector{Char}
    nlb::Int
end
Block() = Block(Vector{Char}(), 0)
import Base.push!

function push!(block::Block, chars::Vector{Char})
    for c in chars
        if c == '('
            block.nlb += 1
        elseif c == ')'
            block.nlb -= 1
        end
        push!(block.chars, c)
    end
end

function ok(block::Block)
    return block.nlb == 0
end

ChineseTreeBank = Vector{Vector{ChineseTree}}

function parsectb(ctbrootpath::String)
    olddir = pwd()
    newdir = joinpath(realpath(ctbrootpath), "data", "bracketed")
    cd(newdir)
    res = Vector{Vector{ChineseTree}}()
    for (i, f) in enumerate(readdir("."))
        resf = Vector{ChineseTree}()
        push!(res, resf)
        block = Block()
        open(f, "r") do io
            for line in eachline(io)
                if startswith(line, "(")
                    push!(block, convert(Vector{Char}, line))
                    if !ok(block)
                        for line in eachline(io)
                            push!(block, convert(Vector{Char}, line))
                            if ok(block) break end
                        end
                    end
                    push!(resf, ChineseTree(block.chars))
                    block = Block()
                end
            end
        end
    end
    cd(olddir)
    return res
end

# ctb = parsectb("data/ctb8.0")

using DataFrames
import Base.stat
function stat(ctb::ChineseTreeBank)
    from = Vector{String}(); to = Vector{Vector{String}}()
    from2 = Vector{String}(); to2 = Vector{String}()
    function visitor(tree, cur)
        nchds = length(tree.adj[cur])
        if nchds > 0
            if nchds == 1
                chd = tree.adj[cur][1]
                if length(tree.adj[chd]) == 0
                    if tree.label[cur] != "-NONE-"
                        push!(from2, tree.label[cur])
                        push!(to2, tree.label[chd])
                    end
                elseif tree.label[chd] != "-NONE-"
                    push!(from, tree.label[cur])
                    push!(to, tree.label[tree.adj[cur]])
                end
            else
                push!(from, tree.label[cur])
                push!(to, tree.label[tree.adj[cur]])
            end
        end
    end
    for vec in ctb
        for tree in vec
            dfstraverse(tree, visitor)
        end
    end
    function f(df::DataFrame)
        return by(df, [:from, :to], tot = :from => length, sort = true)
    end
    inn = f(DataFrame(from = from, to = to))
    pos = f(DataFrame(from = from2, to = to2))
    inn, pos
end

function posword(ct::ChineseTree)
    res = Vector{Tuple{String, String}}()
    function visitor(tree, cur)
        nchds = length(tree.adj[cur])
        if nchds == 1
            chd = tree.adj[cur][1]
            if length(tree.adj[chd]) == 0
                push!(res, (tree.label[cur], tree.label[chd]))
            end
        end
    end
    dfstraverse(ct, visitor)
    return res
end

function writeposword(filepath::String, ctb::ChineseTreeBank)
    open(filepath, "w") do io
        for ctv in ctb
            for tree in ctv
                res = filter(x -> x[1] != "-NONE-", posword(tree))
                println(io, length(res))
                for r in res
                    println(io, r[1], " ", r[2])
                end
            end
        end
    end
end
