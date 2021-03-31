require "test_helper"
require "dgd-tools/dgd-doc"

class DGDParserTest < Minitest::Test
  def initialize(*args)
    super
    @test_dir = __dir__
    @dgd_source_dir = File.join(@test_dir, "dgd_source")
    @skotos_dir = File.join(@dgd_source_dir, "skotos")
  end

  def test_inherits_only
    sf = DGD::Doc::SourceFile.new(File.join(@dgd_source_dir, "inherit_test.c"), dgd_root: @dgd_source_dir)
  end

  def test_trivial_preprocessor
    # This file, if used alone, preprocesses to nothing since it just defines macros.
    sf = DGD::Doc::SourceFile.new(File.join(@skotos_dir, "include/System.h"), dgd_root: @skotos_dir)
  end

end
