require "dgd-tools/version"

require "treetop"

Treetop.load "#{__dir__}/dgd_grammar.tt"

module DGD; end

module DGD::Doc

  class SourceFile
    def initialize(path)
      unless File.exist?(path)
        raise "No such source file for DGD::Doc::Sourcefile: #{path.inspect}"
      end

      @parser = DGDGrammarParser.new

      @path = path
      parse_contents
    end

    private

    def parse_contents
      s = File.read(@path)

      data = @parser.parse(s)
      unless data
        if !data
          puts @parser.failure_reason
          puts @parser.failure_line
          puts @parser.failure_column
        end
        raise "Parse error!"
      end
    end
  end
end
