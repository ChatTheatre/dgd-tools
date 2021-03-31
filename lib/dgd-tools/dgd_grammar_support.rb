#class StringLiteral < Treetop::Runtime::SyntaxNode
#  def some_name
#    # This is a pretty crude way of handling character escaping, etc.
#    return eval self.text_value
#  end
#end

class DataDecl < Treetop::Runtime::SyntaxNode
end

class FuncDecl < Treetop::Runtime::SyntaxNode
end

class Inherit < Treetop::Runtime::SyntaxNode
end

class Identifier < Treetop::Runtime::SyntaxNode
end

class DecimalLiteral < Treetop::Runtime::SyntaxNode
end

class OctalLiteral < Treetop::Runtime::SyntaxNode
end

class HexadecimalLiteral < Treetop::Runtime::SyntaxNode
end

class FloatLiteral < Treetop::Runtime::SyntaxNode
end

class StringLiteral < Treetop::Runtime::SyntaxNode
end

class CharLiteral < Treetop::Runtime::SyntaxNode
end
