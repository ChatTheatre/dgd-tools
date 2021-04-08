module DGD;end

module DGD::Doc
  LEGAL_MODIFIERS = %w(private static atomic nomask varargs)
  LEGAL_TYPES = %w(int float string object mapping mixed void)

  class SourceObject
    attr_reader :loc
    attr_reader :source

    def initialize(loc:, source:)
      @loc = loc
      @source = source
    end
  end

  class Inherit < SourceObject
    attr_reader :private
    attr_reader :label
    attr_reader :object_name

    def initialize(loc:, source:, private:, label:, object_name:)
      @private = private
      @label = label
      @object_name = object_name
      super(loc: loc, source: source)
    end
  end

  class Method < SourceObject
    attr_reader :comment
    attr_reader :full_text
    attr_reader :modifiers
    attr_reader :type
    attr_reader :name
    attr_reader :args

    def initialize(loc:, source:, comment:, full_text:, modifiers:, return_type:, name:, args:)
      illegal_modifiers = modifiers - LEGAL_MODIFIERS
      raise "Illegal modifiers passed to DGD::Doc::Method! #{illegal_modifiers.inspect}" unless illegal_modifiers.empty?

      super(loc:loc, source:source)

      @comment = comment
      @full_text = full_text
      @modifiers = modifiers
      @return_type = return_type
      @name = name
      @args = args
    end
  end

  class Variable < SourceObject
    attr_reader :comment
    attr_reader :full_text
    attr_reader :modifiers
    attr_reader :type
    attr_reader :name

    def initialize(loc:, source:, comment:, full_text:, modifiers:, type:, name:)
      illegal_modifiers = modifiers - LEGAL_MODIFIERS
      raise "Illegal modifiers passed to DGD::Doc::Method! #{illegal_modifiers.inspect}" unless illegal_modifiers.empty?

      super(loc: loc, source: source)

      @comment = comment
      @full_text = full_text
      @modifiers = modifiers
      @type = type
      @name = name
    end
  end

  class SourceFile
    attr_reader :inherits
    attr_reader :data_decls
    attr_reader :func_decls
    attr_reader :fully_parsed

    def initialize(path, dgd_root:, preprocess: false, parse_contents: true)
      unless File.exist?(path)
        raise "No such source file for DGD::Doc::Sourcefile: #{path.inspect}"
      end

      @path = path
      @dgd_root = dgd_root
      @preprocess = preprocess
      @fully_parsed = false

      do_parse_contents if parse_contents
    end

    private

    # This large method is basically the interface between the complex regular expressions
    # above and the more structured content of @inherits, @func_decls and @data_decls.
    # It could be broken up further, but it's hard to avoid entanglement with the regular
    # expressions.
    #
    # Separable concerns like the format of the comments themselves should be extracted
    # into their own separate methods, keeping this one as the tarpit of regexp handling.
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

      @inherits = inherits.map do |inh|
        fulltext, priv, label, obname = *inh
        loc = intermediate.index(fulltext)
        Inherit.new loc: loc, source: self, private: !!priv, label: label, object_name: obname
      end

      locations = {} # maps from full item text to location in the source
      (doc_comments.map { |i| i[0] } +
        data_decls.map { |i| i[0] } +
        func_decls.map { |i| i[0] }).each do |item|

        loc = intermediate.index(item)

        # Hideous hack: only include global data and function declarations, not locals or func calls,
        # by only including declarations after a newline or start-of-document.
        next if loc != 0 && intermediate[loc - 1] != "\n"

        locations[item] = loc

        # Our current approach messes up if something occurs exactly identically more than once, so we check.
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

      @data_decls = {}
      @func_decls = {}
      last_comment = nil

      locs_to_items.keys.sort.each do |loc|
        item = locs_to_items[loc]
        if (idx = doc_comments.index { |dd| dd[0] == item })
          # Item is a comment
          if last_comment
            puts "Warning: comment without matching data or function declaration! #{last_comment.inspect}"
          end

          _, comment_block = *doc_comments[idx]

          last_comment = comment_block
          next
        end

        # Also allow us to skip a declaration, real or mistaken, with a /** skip */ comment
        if last_comment && last_comment.strip == "skip"
          last_comment = nil
          next
        end

        if (idx = data_decls.index { |dd| dd[0] == item })
          # Item is a data declaration
          ft, raw_mods, raw_datatype, varname = *data_decls[idx]
          mods = (raw_mods || "").split(/\s+/)
          datatype = raw_datatype.gsub(/\s+/, "")
          comment = comment_text_to_structured(last_comment)

          raise "Two pieces of global data shouldn't have the same name! name: #{varname.inspect}" if @data_decls[varname]
          var_item = Variable.new loc: loc, source: self, comment: comment, full_text: ft, modifiers: mods, type: datatype, name: varname
          @data_decls[varname] = var_item
          last_comment = nil
          next
        end

        # Otherwise it had better be a function declaration
        idx = func_decls.index { |fd| fd[0] == item }
        raise "Internal error: can't figure out type of item! #{item.inspect}!" unless idx
        ft, raw_mods, raw_return_type, func_name, args_raw = *func_decls[idx]

        mods = (raw_mods || "").split(/\s+/)
        return_type = (raw_return_type || "").gsub(/\s+/, "")
        comment = comment_text_to_structured(last_comment)

        # For each argument, turn all whitespace to a single space, and spaces around stars go
        # away - "int **v" becomes "int**v", while "mapping\n   baloo" becomes "mapping baloo"
        args = args_raw.split(",").map { |arg| arg.gsub(/\s+/, " ").gsub(/ ?\* ?/, "*") }

        # If there's two of the same function name, that normally means a prototype and a definition.
        # We're doing little enough parsing that I don't (yet) want to merge them or check for
        # agreement.
        if @func_decls[func_name]
          if last_comment
            puts "Warning: function #{func_name.inspect} has multiple DGD-doc comments in file #{@path.inspect}!" if @func_decls[func_name][:comment]
          else
            last_comment = @func_decls[func_name].comment
          end
        end
        fd = Method.new loc: loc, source: self, comment: comment, full_text: ft, modifiers: mods, return_type: return_type, name: func_name, args: args
        @func_decls[func_name] = fd
        last_comment = nil
      end

      @fully_parsed = true
    end

    def comment_text_to_structured(comment_text)
      if !comment_text
        return nil
      end
      all_lines = comment_text.split("\n").map { |line| line.gsub(/^\s*#\s/, "") }
      tag_lines, nontag_lines = all_lines.partition { |line| line =~ TAG_LINE_REGEXP }

      tags = []
      tag_lines.each do |line|
        m = TAG_LINE_REGEXP.match(line)
        raise("Internal error: can't re-match TAG_LINE_REGEXP!") unless m
        tag, contents = *m.captures
        unless DOC_TAGS.include?(tag)
          puts "Warning: unknown documentation tag #{tag.inspect} in file #{@path}!"
        end
        tags.push [ tag, contents ]
      end

      htmlified = Kramdown::Document.new(nontag_lines.join("\n")).to_html
      return({ orig: comment_text, tags: tags, html_body: htmlified })
    end
  end
end
