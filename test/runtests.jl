using Test, ChineseTokenizers, Pkg

@testset "Result of split is meaningful and IO is correct." begin
    tk = ChineseTokenizers.chmm()
    display(tk)
    segs = split("这是樊胜美的妈吗", tk)
    println()
    @show segs
    open(joinpath(dirname(pathof(ChineseTokenizers)), "..", "chmm"), "w") do io
        write(io, tk)
    end
    tk2 = open(joinpath(dirname(pathof(ChineseTokenizers)), "..", "chmm"), "r") do io
        read(io, HiddenMarkovModel)
    end
    @test tk == tk2
end

@testset "Added userdict should makes sense." begin
    tk1 = HiddenMarkovModel()
    xs  = "这是樊胜美的妈吗"
    segs1 = split(xs, tk1)
    @show segs1
    tk2 = HiddenMarkovModel{Float32, Int32}(; userdict = joinpath(dirname(pathof(ChineseTokenizers)), "..", "userdict"))
    segs2 = split(xs, tk2)
    @show segs2
    @test length(segs1) > length(segs2)
end

@testset "Added poswords may makes sense." begin
    tk1 = HiddenMarkovModel()
    xs  = "我的话你是不是不听了？"
    segs1 = split(xs, tk1)
    @show segs1
    tk2 = HiddenMarkovModel{Float32, Int32}(; poswords = joinpath(dirname(pathof(ChineseTokenizers)), "..", "poswords"))
    segs2 = split(xs, tk2)
    @show segs2
    @test length(segs1) >= length(segs2)
end

# @testset "Read and write is correct." begin
#     xs =  """
#     ( (IP (NP-TMP (NT 10月)
#     (NT 2号) )
#     (PU ，)
#     (NP-SBJ (-NONE- *pro*))
#     (VP (VE 有)
#     (IP-OBJ (NP-SBJ (NP (NN 患者) )
#     (CC 及)
#     (NP (NP (PN 其) )
#     (NP (NN 家属) ) ) )
#     (VP (VP (VP (VV 到)
#     (NP-OBJ-PN (NR 桐城市)
#     (NN 人民)
#     (NN 医院) ) )
#     (VP (VV 去)
#     (VP (VV 看病) ) ) )
#     (PU ，)
#     (VP (PP-PRP (P 因)
#     (IP (NP-SBJ (NN 护士)
#     (NN 嗓门) )
#     (VP (VA 大)
#     (ADVP (AD 些) ) ) ) )
#     (PU ，)
#     (ADVP (AD 便) )
#     (VP (VV 大打出手) ) )
#     (PU ，)
#     (VP (BA 将)
#     (IP-OBJ (NP-SBJ-1 (NP (DNP (NP (NN 医院) )
#     (DEG 的) )
#     (NP (NN 急诊科)
#     (NN 医生) ) )
#     (NP-PN (NR 杨辉) ) )
#     (VP (VP (ADVP (AD 狠) )
#     (VP (VV 揣)
#     (NP-OBJ (-NONE- *-1))) )
#     (PU ，)
#     (VP (VV 打成)
#     (NP-OBJ (NN 骨折) ) ) ) ) ) ) ) )
#     (PU 。) ) )
#     """
#     obj = ChineseTree(xs)
#     display(obj)
#     ctb = parsectb()
#     model = CykModel(ctb)
#     p = 0; t = nothing
#     @time p, t = cyk(posword(obj), model)
#     @show p
#     display(decnf(t))
# end
