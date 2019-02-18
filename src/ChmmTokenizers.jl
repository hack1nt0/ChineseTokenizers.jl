module ChmmTokenizers

import Base: split, display, read, write

# using AhoCorasickAutomatons
using Pkg

export ChmmTokenizer
# export parsectb, CykModel, cyk, posword, ChineseTree, cnf,
#     decnf

import Base: in, eachmatch, read, write, display,
    summarysize, format_bytes, resize!, isless, ==, print, get
using Markdown, ProgressMeter

include("AhoCorasickAutomaton.jl")
include("ChmmTokenizer.jl")
include("ChineseTrees.jl")
include("cyks.jl")

POS = Markdown.MD(Markdown.Table(Any[["CTB_POS", "PKU_POS", "summary"],
                ["NR", "", "专属名词"],
                ["NT", "", "时间"],
                ["NN", "", "其他"],
                ["PN", "", "代词"],
                ["VA", "", "形容词动词化"],
                ["VC", "", "be, not be 对应的中文"],
                ["VE", "", "have, not have 对应的中文"],
                ["VV", "", "其他"],
                ["P", "", "介词"],
                ["LC", "", "方位词"],
                ["AD", "", "副词"],
                ["DT", "", "谁的，哪一个"],
                ["CD", "", "量词"],
                ["OD", "", "序词"],
                ["M", "", "量词"],
                ["CC", "", "连词"],
                ["CS", "", "连词"],
                ["DEC", "", "的"],
                ["DEG", "", "的"],
                ["DER", "", "得"],
                ["DEV", "", "地"],
                ["AS", "", "Aspect Particle 表达英语中的进行式、完成式的词，比如（着，了，过）"],
                ["SP", "", "句子结尾词（了，吧，呢，啊，呀，吗）"],
                ["ETC", "", "等（等）"],
                ["MSP", "", "其他"],
                ["IJ", "", "句首感叹词"],
                ["ON", "", "象声词"],
                ["LB", "", "被"],
                ["SB", "", "被"],
                ["BA", "", "把"],
                ["JJ", "", "名词修饰词"],
                ["PU", "", "标点符号"],
                ["FW", "", "POS不清楚的词（不是外语词）"]], Symbol[:l, :l, :l]));
end # module
