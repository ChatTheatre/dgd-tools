#class StringLiteral < Treetop::Runtime::SyntaxNode
#  def some_name
#    # This is a pretty crude way of handling character escaping, etc.
#    return eval self.text_value
#  end
#end

module DGDGrammar

  class TopDecl < Treetop::Runtime::SyntaxNode
  end

  class DataDecl < TopDecl
  end

  class FuncDecl < TopDecl
  end

  class Inherit < Treetop::Runtime::SyntaxNode
  end

  class Identifier < Treetop::Runtime::SyntaxNode
  end

  class StringLiteral < Treetop::Runtime::SyntaxNode
  end

  class CComment < Treetop::Runtime::SyntaxNode
  end

end
