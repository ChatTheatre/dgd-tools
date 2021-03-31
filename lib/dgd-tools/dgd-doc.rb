require "dgd-tools/version"

require "treetop"

Treetop.load "#{__dir__}/dgd_grammar.tt"

# Preprocessor incantation: cpp -C -I. -D__DGD__ name_of_file.c

module DGD; end

module DGD::Doc

  class SourceFile
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
      #preproc_output.gsub! /\n+/, "\n"  # The preprocessor often winds up leaving a lot of newlines from various sources

      data = @parser.parse(preproc_output)
      unless data
        if !data
          puts @parser.failure_reason
          puts @parser.failure_line
          puts @parser.failure_column

          puts "Preproc output was:#{preproc_output}\n\n\n"
        end
        raise "Parse error!"
      end
    end
  end
end
