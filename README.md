# ChineseTokenizers.jl
Word tokenizer for Chinese.

# Todo
抽取词典中难以枚举的 **整体** 词

1. 代词，比如她、这件事情 and (姓+)职称

2. 日期、数词 and 电话号码

3. 结构性的实体，比如邮件地址、网络地址

4. 人名

# 思路
抽取语法结构词，构建语法树，按照其概率逆向抽取其他部分（这部分可能正向难以抽取）
