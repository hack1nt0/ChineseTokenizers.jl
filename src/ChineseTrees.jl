
struct ChineseTree
    label::String
    adj::Vector{ChineseTree}
    # prob::Float64
end

function label(s::String)
    t = findfirst(!isletter, s)
    return (t == nothing || t == 1) ? s : s[1:t - 1]
end

isleaf(tree::ChineseTree) = length(tree.adj) == 0
isposn(tree::ChineseTree) = length(tree.adj) == 1 && isleaf(tree.adj[1])

function dfstraverse(tree::ChineseTree, visitor::Function)
    for chd in tree.adj
        dfstraverse(chd, visitor)
    end
    visitor(tree)
    return nothing
end

function ChineseTree(chars::Vector{Char}; l = findfirst(isequal('('), chars), trim = label)
    nchar = length(chars)
    l += 1
    r = l
    while chars[r] != '(' && chars[r] != ')' r += 1 end
    if (chars[r] == ')')
        ss = split(join(chars[l:r - 1]))
        @assert length(ss) == 2
        leaf = ChineseTree(String(ss[2]), ChineseTree[])
        posn = ChineseTree(trim(String(ss[1])), ChineseTree[leaf])
        return posn
    else
        @assert chars[r] == '('
        ss = split(join(chars[l:r - 1]))
        # @assert length(ss) == 1 string(l, "  ", chars)
        if length(ss) == 0
            return ChineseTree(chars; l = r)
        end
        @assert length(ss) == 1
        fa = ChineseTree(trim(String(ss[1])), ChineseTree[])
        # setlabel!(obj, cur, ss[1])
        nlb = 1
        while nlb > 0
            if (chars[r] == '(')
                if nlb == 1 l = r end
                nlb += 1
            elseif chars[r] == ')'
                nlb -= 1
                if nlb == 1
                    push!(fa.adj, ChineseTree(chars; l = l, trim = trim))
                end
            end
            r += 1
        end
        return fa
    end
end

function tochars(s::String)
    cps = Vector{Char}(undef, length(s))
    for (i, cp) in enumerate(s)
        cps[i] = cp
    end
    return cps
end
ChineseTree(ct::String; trim = label) = ChineseTree(tochars(ct); trim = trim)

import Base.size
function size(tree::ChineseTree)
    if isleaf(tree) return (1, 1)
    else
        h = w = 0
        for chd in tree.adj
            ch, cw = size(chd)
            h += ch; w = max(w, cw + 1)
        end
        return (h, w)
    end
end

import Base.display

function display(obj::ChineseTree)
    xlim, ylim = size(obj)
    mat = fill("", xlim, ylim)
    ileaf = 1
    colors = Dict{String, Int}()
    edges = Vector{Tuple{Int, Int, Int, Int}}()
    function dfs(cur::ChineseTree)
        if !haskey(colors, cur.label)
            colors[cur.label] = (1 + (length(colors) + 1) * 10) % 256
        end
        if isleaf(cur)
            mat[ileaf, ylim] = cur.label
            ileaf += 1
            return (ileaf - 1, ylim)
        else
            cxys = Vector{Tuple{Int, Int}}()
            x = xlim; y = ylim;
            for chd in cur.adj
                cx, cy = dfs(chd)
                x = min(x, cx)
                y = min(y, cy - 1)
                push!(cxys, (cx, cy))
            end
            for cxy in cxys push!(edges, (x, y, cxy[1], cxy[2])) end
            mat[x, y] = cur.label
            return (x, y)
        end
    end
    dfs(obj);
    for (lx, ly, rx, ry) in edges
        for x = lx + 1:rx - 1
            new = old = mat[x, ly]
            if old == "" new = "│" end
            if old == "└" new = "├" end
            mat[x, ly] = new
        end
        if lx < rx mat[rx, ly] = "└" end
        mat[rx, ly + 1:ry - 1] .= "─";
    end
    yw = mapreduce(length, max, mat; dims = 1) .+ 2
    for x = 1:xlim, y = 1:ylim
        s = mat[x, y]; ns = length(s)
        # words
        if y == ylim println(" ", s); continue end
        padl = div(yw[y] - ns, 2)
        if (y == ylim - 1)
            padl = yw[y] - ns
        end
        padr = yw[y] - ns - padl
        padlc = padrc = '─'
        if s == "" || s == "│"
            padlc = padrc = ' '
        elseif s == "└" || s == "├" || x == 1 && y == 1
            padlc = ' '
        end
        ns = padlc ^ padl * s * padrc ^ padr
        for i = 1:padl print(padlc) end
        if haskey(colors, s) printstyled(s; color = colors[s]) else print(s) end
        for i = 1:padr print(padrc) end
    end
    return nothing
end

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

const ChineseTreeBank = Vector{Vector{ChineseTree}}

function parsectb(;ctbrootpath::String = "/Users/dy/ChineseTokenizers.jl/data/ctb8.0", trim = label)
    olddir = pwd()
    newdir = joinpath(realpath(ctbrootpath), "data", "bracketed")
    res = Vector{Vector{ChineseTree}}()
    cd(() -> begin
    for (i, f) in enumerate(readdir("."))
        resf = Vector{ChineseTree}()
        push!(res, resf)
        block = Block()
        open(f, "r") do io
            for line in eachline(io)
                if startswith(line, "(")
                    push!(block, tochars(line))
                    if !ok(block)
                        for line in eachline(io)
                            push!(block, tochars(line))
                            if ok(block) break end
                        end
                    end
                    push!(resf, ChineseTree(block.chars; trim = trim))
                    block = Block()
                end
            end
        end
    end
end, newdir)
    return res
end

# ctb = parsectb("data/ctb8.0")

# using DataFrames
# import Base.stat
# function stat(ctb::ChineseTreeBank)
#     from = Vector{String}(); to = Vector{Vector{String}}()
#     from2 = Vector{String}(); to2 = Vector{String}()
#     function visitor(tree, cur)
#         nchds = length(tree.adj[cur])
#         if nchds > 0
#             if nchds == 1
#                 chd = tree.adj[cur][1]
#                 if length(tree.adj[chd]) == 0
#                     if tree.label[cur] != "-NONE-"
#                         push!(from2, tree.label[cur])
#                         push!(to2, tree.label[chd])
#                     end
#                 elseif tree.label[chd] != "-NONE-"
#                     push!(from, tree.label[cur])
#                     push!(to, tree.label[tree.adj[cur]])
#                 end
#             else
#                 push!(from, tree.label[cur])
#                 push!(to, tree.label[tree.adj[cur]])
#             end
#         end
#     end
#     for vec in ctb
#         for tree in vec
#             dfstraverse(tree, visitor)
#         end
#     end
#     function f(df::DataFrame)
#         return by(df, [:from, :to], tot = :from => length, sort = true)
#     end
#     inn = f(DataFrame(from = from, to = to))
#     pos = f(DataFrame(from = from2, to = to2))
#     inn, pos
# end

function posword(ct::ChineseTree)
    res = Vector{Tuple{String, String}}()
    function visitor(cur)
        if isposn(cur) push!(res, (cur.label, cur.adj[1].label)) end
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
# ChineseTreeNode = Union{InnerTreeNode, PosTreeNode, LeafTreeNode}
# ChineseTreeNode(label::String, id::String) == InnerTreeNode(label, id, Int[], 0.0)

function cnf(root::ChineseTree)::ChineseTree
    nchd = length(root.adj)
    if nchd == 0
        return root
    elseif nchd <= 2
        newroot = ChineseTree(root.label, ChineseTree[])
        for i = 1:nchd push!(newroot.adj, cnf(root.adj[i])) end
        return newroot
    else
        newroot = ChineseTree(root.label, ChineseTree[])
        newright = ChineseTree(join(map(x -> x.label, root.adj[2:end]), "+"), root.adj[2:end])
        push!(newroot.adj, cnf(root.adj[1]))
        push!(newroot.adj, cnf(newright))
        return newroot
    end
end

function decnf(root::ChineseTree)
    nodes = decnf2(root)
    return length(nodes) == 1 ? nodes[1] : ChineseTree(join(map(x -> x.label, nodes), "+"), nodes)
end

function decnf2(root::ChineseTree)::Vector{ChineseTree}
    nchd = length(root.adj)
    if nchd == 0 return ChineseTree[root] end
    if nchd == 1
        newroot = ChineseTree(root.label, decnf2(root.adj[1]))
        return ChineseTree[newroot]
    end
    newroot = ChineseTree(root.label, append!(decnf2(root.adj[1]), decnf2(root.adj[2])))
    istmp = in('+', root.label)
    return istmp ? newroot.adj : ChineseTree[newroot]
end

import Base.==
function ==(obj1::ChineseTree, obj2::ChineseTree)
    res = obj1.label == obj2.label
    if !res return false end
    if length(obj1.adj) != length(obj2.adj) return false end
    for i in 1:length(obj1.adj)
        if obj1.adj[i] != obj2.adj[i] return false end
    end
    return true
end
