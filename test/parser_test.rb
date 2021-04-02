require "test_helper"
require "dgd-tools/dgd-doc"

class DGDParserTest < Minitest::Test
  def initialize(*args)
    super
    @test_dir = __dir__
    @dgd_source_dir = File.join(@test_dir, "dgd_source")
    @skotos_dir = File.join(@dgd_source_dir, "skotos")
  end

  def test_inherit_regexp
    assert DGD::Doc::INHERIT_REGEXP =~ 'inherit "/any/path/works"   ;', "Basic inherit statement doesn't match INHERIT_REGEXP"
  end

  def test_inherits_only
    sf = DGD::Doc::SourceFile.new File.join(@dgd_source_dir, "inherit_test.c"), dgd_root: @dgd_source_dir
    assert_equal ["access", nil, "label_goes_here", nil], sf.inherits.map { |inh| inh[:label] }, "Can't correctly match all labels in inherit_test.c"
  end

  #def test_functions
  #  DGD::Doc::SourceFile.new File.join(@dgd_source_dir, "function_test.c"), dgd_root: @dgd_source_dir
  #end

  def test_trivial_preprocessor
    # This file, if used alone, preprocesses to nothing since it just defines macros.
    sf = DGD::Doc::SourceFile.new File.join(@skotos_dir, "include/System.h"), dgd_root: @skotos_dir
    assert_equal [], sf.inherits, "Should correctly parse no inherits in include/System.h"
    assert_equal [], sf.data_decls, "Should correctly parse no data declarations in include/System.h"
    assert_equal [], sf.func_decls, "Should correctly parse no function declarations in include/System.h"
  end

  def test_skotos_source_files
    sf = DGD::Doc::SourceFile.new File.join(@skotos_dir, "lib/version.c"), dgd_root: @skotos_dir

    assert_equal [], sf.data_decls, "In version.c, we should ignore the local variable instead of including it in data_decls"
    #DGD::Doc::SourceFile.new File.join(@skotos_dir, "httpconn.c"), dgd_root: @skotos_dir
  end

end
