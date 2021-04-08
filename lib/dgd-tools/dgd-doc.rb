require "dgd-tools/version"
require "dgd-tools/dgd-doc-parsing"

require "kramdown"

module DGD; end

module DGD::Doc
  DOC_COMMENT_REGEXP = %r{(?<fulltext>/\*\*(?<body>(.|\n)*?)\*/)}
  INHERIT_REGEXP = /(?<fulltext>(?<private>private\s+)?inherit(\s+(?<label>[a-zA-Z_][a-zA-Z_0-9]*))?(\s+object)?\s*(?<obname>.*?)\s*;)/
  DATA_DECL_REGEXP = /(?<fulltext>(?<modifiers>(private|static|atomic|nomask|varargs)\s+)*(?<datatype>(int|float|string|object|mapping|mixed|void)\s*(\**\s*))(?<varname>[a-zA-Z_][a-zA-Z_0-9]*)\s*;)/
  FUNC_DECL_REGEXP = /(?<fulltext>(?<modifiers>(private|static|atomic|nomask|varargs)\s+)*(?<returntype>(int|float|string|object|mapping|mixed|void)\s*(\**\s*))?(?<funcname>[a-zA-Z_][a-zA-Z_0-9]*)\s*\((?<args>.*)\)\s*(;|{))/

  TAG_LINE_REGEXP = /@(?<tag>[A-Za-z_]{3,}) (?<contents>.*)$/

  # Want to be inspired? There's a great set of tags in Yard: https://github.com/lsegal/yard/blob/main/lib/yard/tags/library.rb
  # Search for define_tag.

  DOC_TAGS = [ "param", "return", "example", "deprecated", "note", "private", "raise", "see" ]

end
