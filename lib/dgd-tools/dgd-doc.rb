require "dgd-tools/version"

require "treetop"

require_relative "dgd_grammar_support"
Treetop.load "#{__dir__}/dgd_grammar.tt"

module DGD; end

module DGD::Doc

  class SourceFile
    attr_reader :parser

    def initialize(path, dgd_root:, preprocess: true, parse_contents: true)
      unless File.exist?(path)
        raise "No such source file for DGD::Doc::Sourcefile: #{path.inspect}"
      end

      @parser = DGDGrammarParser.new
      @path = path
      @dgd_root = dgd_root
      @preprocess = preprocess

      do_parse_contents if parse_contents
    end

    private

    def do_parse_contents
      intermediate = nil
      if @preprocess
        intermediate = `cpp -C -I#{@dgd_root}/include -D__DGD__ #{@path}`
        intermediate.gsub!(/^# \d+ ".*"\s*\d*$/, "")
        #intermediate.gsub!(/\n+/, "\n")  # The preprocessor often winds up leaving a lot of newlines from various sources
      else
        intermediate = File.read @path
      end
      data = @parser.parse(intermediate, root: "source_file")
      if data
        clean_tree(data)
        #puts data.inspect
      else
        puts @parser.failure_reason

        #puts "Preproc output was:#{intermediate}\n"
        preproc_lines = intermediate.split("\n")
        puts "Preprocessed failing line:\n#{preproc_lines[@parser.failure_line - 1]}\n"
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
