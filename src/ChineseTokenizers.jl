module ChineseTokenizers

import Base: split, display, read, write

using Markdown, AhoCorasickAutomatons, Pkg

export ChineseTokenizer

include("ChineseTokenizer.jl")

end # module
