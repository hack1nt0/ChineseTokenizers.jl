function splits(text::AbstractString, obj::ChmmTokenizer; ntrial = 2, pos = true)
    codes = codeunits(text)
    aca = obj.aca; pos = obj.pos;
    hpr = obj.hpr; h2h = obj.h2h;
    alpha = obj.alpha; h2v = obj.h2v;
    positions = collect(eachmatch(aca, text))
    if (length(positions) == 0) return [String(text)] end
    ncode = length(codes); npos = length(pos);
    dp = Array{Float64, 3}(undef, ntrial, npos, ncode + 1); dp .= 1.0 / 0.0; dp[1, 1, ncode + 1] = 0.0;
    nx = Array{Tuple{Int, Int, Int}, 3}(undef, ntrial, npos, ncode + 1)
    j = length(positions)
    charindexes = collect(eachindex(text)); push!(charindexes, ncode + 1);
    k = nchar = length(charindexes) - 1
    for i = ncode:-1:1
        while j > 0 && i < positions[j].t j -= 1 end
        while j > 0 && i == positions[j].t
            iword = positions[j].i
            s = positions[j].s
            t = positions[j].t
            for ipos = 1:npos
                res = view(dp, :, ipos, s)
                H2V = get(h2v[ipos], iword, alpha[ipos])
                nxt = view(nx, :, ipos, s)
                for ipos2 = 1:npos
                    for itrial2 = 1:ntrial
                        cur = H2V + h2h[ipos2, ipos] + dp[itrial2, ipos2, t + 1]
                        for itrial = 1:ntrial
                            if cur < res[itrial]
                                res[itrial + 1:end] .= res[itrial:end - 1]
                                nxt[itrial + 1:end] .= nxt[itrial:end - 1]
                                res[itrial] = cur
                                nxt[itrial] = (itrial2, ipos2, t)
                                # @show itrial, ipos, s, itrial2, ipos2, t + 1
                                break
                            end
                        end
                    end
                end
            end
            j -= 1
        end
        if i == charindexes[k]
            iword = 0
            s = i
            t = charindexes[k + 1] - 1
            for ipos = 1:npos
                res = view(dp, :, ipos, s)
                H2V = get(h2v[ipos], iword, alpha[ipos])
                nxt = view(nx, :, ipos, s)
                for ipos2 = 1:npos
                    for itrial2 = 1:ntrial
                        cur = H2V + h2h[ipos2, ipos] + dp[itrial2, ipos2, t + 1]
                        for itrial = 1:ntrial
                            if cur < res[itrial]
                                res[itrial + 1:end] .= res[itrial:end - 1]
                                nxt[itrial + 1:end] .= nxt[itrial:end - 1]
                                res[itrial] = cur
                                nxt[itrial] = (itrial2, ipos2, t)
                                break
                            end
                        end
                    end
                end
            end
            k -= 1
        end
    end
    # dp[:, :, 1] .+= hpr
    for i = 1:ntrial dp[i, :, 1] .+= hpr end
    res = Vector()
    dp1 = dp[:, :, 1]
    for i = 1:ntrial
        minind = findmin(dp1)[2]
        dp1[minind] = 1.0 / 0.0
        itrial = minind[1]
        ipos = minind[2]
        pvis = 1
        segs = Vector{Tuple{String, String}}()
        while pvis <= ncode
            # @show nx[ipos, pvis]
            nxt = nx[itrial, ipos, pvis]
            itrial2 = nxt[1]
            ipos2 = nxt[2]
            pvis2 = nxt[3]
            push!(segs, (pos[ipos], String(codes[pvis:pvis2])))
            itrial = itrial2
            ipos = ipos2
            pvis = pvis2 + 1
        end
        push!(res, segs)
    end
    push!(res, dp[:, :, 1])
    push!(res, nx[:, :, 1])
    return res
end

# function split2(text::AbstractString, obj::ChmmTokenizer; pnp::Float64 = 0.0)
#     codes = codeunits(text)
#     aca = obj.aca; pos = obj.pos;
#     hpr = obj.hpr; h2h = obj.h2h;
#     alpha = obj.alpha; h2v = obj.h2v;
#     nc = length(codes); nh = length(pos);
#     matches = collect(eachmatch(aca, text)); nm = length(matches)
#     if (nm == 0) return [String(text)] end
#     cover = fill(false, nc, nc)
#     for m in matches cover[m.s, m.t] = true end
#     nn = nh * (nc + 1) + nc
#     adj = fill((Inf, 0), nn, nn)
#     for i in 1:nm
#         m = matches[i]
#         for sh in 1:nh, th in 1:nh
#             from = sh * (nc + 1) + m.s; to = th * (nc + 1) + m.t
#             adj[from, to] = (h2h[th, sh] + get(h2v[th], m.i, alpha[th]), i)
#         end
#     end
#     h2nph = obj.h2nph;
#     for i in 1:nm
#         sm = matches[i]
#         for j in nm:-1:i + 1
#             if sm.t + 1 >= matches[j].s break end
#             if cover[sm.t + 1, matches[j].s - 1] continue end
#             tm = matches[j]
#             for sh in 1:nh, th in 1:nh
#                 from = sh * (nc + 1) + sm.s; to = th * (nc + 1) + tm.t
#                 if isinf(adj[from, to][1])
#                     adj[from, to] = (h2nph[th, sh] + pnp + get(h2v[th], tm.i, alpha[th]), j)
#                 end
#             end
#         end
#     end
#     dp = fill(Inf, nh, nc);
#     bk = Matrix{Tuple{Int, Int}}(undef, nh, nc)
#     for sc = 1:nc
#         for sh = 1:nh
#             cur = sc == 1 ? hpr[sh] : dp[sh, sc - 1]
#             from = sh * (nc + 1) + sc
#             for tc = sc + 1:nc
#                 for th = 1:nh
#                     to = th * (nc + 1) + tc
#                     old = dp[th, tc]
#                     new = cur + adj[from, to][1]
#                     if new < old
#                         dp[th, tc] = new
#                         bk[th, tc] = (sh, adj[from, to][2] * (nc + 1) + sc - 1)
#                     end
#                 end
#             end
#         end
#     end
#     tp = findmin(dp[:, nc])[2]
#     @show dp[:, nc], bk[:, nc], tp, matches, alpha
#     tc = nc
#     segs = Vector{Tuple{String, String}}()
#     while tc > 0
#         sp = bk[tp, tc][1]
#         sc = mod(bk[tp, tc][2], (nc + 1))
#         sm = div(bk[tp, tc][2], (nc + 1))
#         lsm = matches[sm].t - matches[sm].s + 1
#         push!(segs, (String(codes[tc - lsm + 1:tc]), pos[tp]))
#         if tc - sc > lsm
#             push!(segs, (String(codes[sc + 1:tc - lsm]), "NS"))
#         end
#         @show sc, tc
#         tp = sp
#         tc = sc
#     end
#     return reverse!(segs)
# end
