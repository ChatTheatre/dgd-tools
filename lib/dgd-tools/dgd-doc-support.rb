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

end
