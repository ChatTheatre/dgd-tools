require "test_helper"
require "dgd-tools/dgd-doc"

class DGDParserTest < Minitest::Test
  def initialize(*args)
    super
    @test_dir = __dir__
    @dgd_source_dir = File.join(@test_dir, "dgd_source")
  end

  def test_inherits_only
    sf = DGD::Doc::SourceFile.new(File.join(@dgd_source_dir, "inherit_test.c"))
  end

end
