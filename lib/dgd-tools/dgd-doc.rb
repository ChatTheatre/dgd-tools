require "dgd-tools/version"

require "treetop"

require_relative "dgd_grammar_support"
Treetop.load "#{__dir__}/dgd_grammar.tt"

# Preprocessor incantation: cpp -C -I. -D__DGD__ name_of_file.c

module DGD; end

module DGD::Doc

  class SourceFile
    attr_reader :parser

    def initialize(path, dgd_root:)
      unless File.exist?(path)
        raise "No such source file for DGD::Doc::Sourcefile: #{path.inspect}"
      end

      @parser = DGDGrammarParser.new
      @path = path
      @dgd_root = dgd_root

      parse_contents
    end

    private

    def parse_contents
      preproc_output = `cpp -C -I#{@dgd_root}/include -D__DGD__ #{@path}`
      preproc_output.gsub!(/\n+/, "\n")  # The preprocessor often winds up leaving a lot of newlines from various sources
      preproc_output.gsub!(/^# \d+ ".*"\w*\d*$/, "")
      data = @parser.parse(preproc_output)
      if data
        clean_tree(data)
        #puts data.inspect
      else
        puts @parser.failure_reason
        puts @parser.failure_line
        puts @parser.failure_column

        puts "Preproc output was:#{preproc_output}\n\n\n"
        raise "Parse error!"
      end
    end

    def clean_tree(root_node)
      return if(root_node.elements.nil?)
      root_node.elements.each {|node| self.clean_tree(node) }
      root_node.elements.delete_if {|node| node.class.name == "Treetop::Runtime::SyntaxNode" && node.text_value.size < 20 }
    end

  end
end
