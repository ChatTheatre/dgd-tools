require "dgd-tools/version"

module DGD; end

module DGD::Doc
  DOC_COMMENT_REGEXP = %r{/\*\*(.*?)\*/}
  INHERIT_REGEXP = /(?<fulltext>(?<private>private\s+)?inherit(\s+(?<label>[a-zA-Z_][a-zA-Z_0-9]*))?(\s+object)?\s*(?<obname>.*?)\s*;)/
  DATA_DECL_REGEXP = /(?<fulltext>(?<modifiers>(private|static|atomic|nomask|varargs)\s+)*(?<datatype>\w+\s*(\**\s*))(?<varname>[a-zA-Z_][a-zA-Z_0-9]*)\s*;)/
  FUNC_DECL_REGEXP = /(?<fulltext>(?<modifiers>(private|static|atomic|nomask|varargs)\s+)*(?<returntype>\w+\s*(\**\s*))?(?<funcname>[a-zA-Z_][a-zA-Z_0-9]*)\s*\((?<args>.*)\)\s*(;|{))/

  class SourceFile
    attr_reader :inherits
    attr_reader :data_decls
    attr_reader :func_decls

    def initialize(path, dgd_root:, preprocess: false, parse_contents: true)
      unless File.exist?(path)
        raise "No such source file for DGD::Doc::Sourcefile: #{path.inspect}"
      end

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
        intermediate.gsub!(/\n+/, "\n")  # The preprocessor often winds up leaving a lot of newlines from various sources
      else
        intermediate = File.read @path
      end
      @source_map = intermediate  # This may have weird mappings of line numbers, etc, so keep a copy

      doc_comments = intermediate.scan DOC_COMMENT_REGEXP
      inherits = intermediate.scan INHERIT_REGEXP
      data_decls = intermediate.scan DATA_DECL_REGEXP
      func_decls = intermediate.scan FUNC_DECL_REGEXP

      @inherits = []
      inherits.each do |inh|
        fulltext, priv, label, obname = *inh
        @inherits.push({ fulltext: fulltext, private: !!priv, label: label, obname: obname })
      end

      locations = {} # maps from full item text to location in the source
      (doc_comments.map { |i| i[0] } +
        data_decls.map { |i| i[0] } +
        func_decls.map { |i| i[0] }).each do |item|
        locations[item] = intermediate.index(item)

        # Everything messes up if something occurs exactly identically more than once, so we check.
        remaining_content = intermediate[(locations[item] + item.size)..-1]
        if remaining_content[item]
          raise "An item occurs identically, more than once in the input! (repeated item: #{item.inspect})"
        end
      end

      all_locs = locations.values
      if all_locs.uniq.size != all_locs.size
        # We shouldn't ever get a data decl at the same place as a comment, inherit or func decl, etc.
        raise "Internal error: parsing more than one category of item at the same exact source location!"
      end
      locs_to_items = locations.invert

      @data_decls = []
      @func_decls = []
      last_comment = nil

      locs_to_items.each do |loc, item|
        if doc_comments.any? { |dc| dc[0] == item }
          # Item is a comment
          if last_comment
            puts "Warning: comment without matching data or function declaration! #{last_comment.inspect}"
          end
          last_comment = item
          next
        end

        if (idx = data_decls.index { |dd| dd[0] == item })
          # Item is a data declaration
          # Hideous hack: only include global data declarations, not local variables,
          # by only including data declarations after a newline or start-of-document.
          next if loc != 0 && intermediate[loc - 1] != "\n"

          ft, raw_mods, raw_datatype, varname = *data_decls[idx]
          mods = (raw_mods || "").split(/\s+/)
          datatype = raw_datatype.gsub(/\s+/, "")
          @data_decls.push({ comment: last_comment, full_text: ft, modifiers: mods, type: datatype, name: varname })
          last_comment = nil
          next
        end

        # Otherwise it had better be a function declaration
        idx = func_decls.index { |fd| fd[0] == item }
        raise "Can't figure out type of item! #{item.inspect}!" unless idx
        ft, raw_mods, raw_returntype, funcname, args_raw = *func_decls[idx]

        mods = (raw_mods || "").split(/\s+/)
        returntype = raw_returntype.gsub(/\s+/, "")

        # For each argument, turn all whitespace to a single space, and spaces around stars go
        # away - "int **v" becomes "int**v", while "mapping\n   baloo" becomes "mapping baloo"
        args = args_raw.split(",").map { |arg| arg.gsub(/\s+/, " ").gsub(/ ?\* ?/, "*") }

        @func_decls.push({ comment: last_comment, full_text: ft, modifiers: mods, type: returntype, name: funcname, args: args })
        last_comment = nil
      end
    end

  end
end
