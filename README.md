# ChineseTokenizers.jl
Word tokenizer for Chinese.

个人见解：没有新词发现的分词器都是耍流氓。分词其实是一个文本理解的过程，是一个自顶向下的过程，而不是一个自底向上的过程，换句话说，分词应该和其上层的词性标注、语法分析甚至是语义分析相结合，作为平等的合作伙伴共荣共赢，而不会仅仅作为他们的底层基础。
但是结合语法分析比较难，一是程序的时间复杂度，二是自然语言语法的复杂性。

# 方法


词性标注和分词结合
1. 分出的结果倾向于总数少？
2. 可以（一定程度的）解决交叉式错误，怎么简单有效的解决组合式错误？

语法分析和分词结合
单个的概率上下文无关算法的时间复杂度就很高，在乘以分词可能性的组合数，简直不敢想。还没有很好的思路

语义分析和分词结合
1. 传统的最大熵和条件随机场（？）已经算是这类方法。不过是利用了一种浅层语义，或叫伪语义。比如当前字的前后几个字（和其组合）。这种语义的缺陷是局部的、会有副作用的。
2. 最大熵不能利用每个字的决策结果来为其他决策提供帮助，CRF可以，但是复杂度太大（？）。

# Todo
抽取词典中难以枚举的 **整体** 词

1. 代词，比如她、这件事情 and (姓+)职称

2. 日期、数词 and 电话号码

3. 结构性的实体，比如邮件地址、网络地址

4. 人名

# 思路
抽取语法结构词，构建语法树，按照其概率逆向抽取其他部分（这部分可能正向难以抽取）
