using Test, ChmmTokenizers, Pkg

@testset "Result of split is meaningful and IO is correct." begin
    tk = ChmmTokenizers.chmm()
    # @show splits("这是樊胜美的妈吗", tokenizer; ntrial = 5)
    # @show splits("这皇后不是白当的", tokenizer; ntrial = 5)
    # @show splits("韩大相公演得好", tokenizer; ntrial = 5)
    r1 = split("这是樊胜美的妈吗", tk)
    @show r1
    io = IOBuffer()
    write(io, tk)
    seek(io, 0)
    tk2 = read(io, ChmmTokenizer)
    @test tk == tk2
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
