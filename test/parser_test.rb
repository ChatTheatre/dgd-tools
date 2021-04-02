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

  def test_functions
    sf = DGD::Doc::SourceFile.new File.join(@dgd_source_dir, "function_test.c"), dgd_root: @dgd_source_dir
    assert_equal ["local_vars_should_parse", "test_args"], sf.func_decls.keys
  end

  def test_trivial_preprocessor
    # This file, if used alone, preprocesses to nothing since it just defines macros.
    sf = DGD::Doc::SourceFile.new File.join(@skotos_dir, "include/System.h"), dgd_root: @skotos_dir
    assert_equal [], sf.inherits, "Should correctly parse no inherits in include/System.h"
    assert_equal [], sf.data_decls.keys, "Should correctly parse no data declarations in include/System.h"
    assert_equal [], sf.func_decls.keys, "Should correctly parse no function declarations in include/System.h"
  end

  def test_skotos_lib_version_c
    sf = DGD::Doc::SourceFile.new File.join(@skotos_dir, "lib/version.c"), dgd_root: @skotos_dir

    assert_equal [], sf.data_decls.keys, "In version.c, we should ignore the local variable instead of including it in data_decls"
    assert_equal ["dgd_version"], sf.func_decls.keys
  end

  def test_skotos_httpconn_c
    sf = DGD::Doc::SourceFile.new File.join(@skotos_dir, "httpconn.c"), dgd_root: @skotos_dir

    assert_equal [ "check_authorization", "check_useragent", "create", "decode_args",
      "disconnect", "finish_auth", "handle_error", "html_connection", "idle_disconnect",
      "log_http", "login", "logout", "message_sent", "pad_zeroes", "query_activex",
      "query_arguments_secure", "query_explorer", "query_header", "query_http_state",
      "query_java", "query_macintosh", "query_mozilla", "query_name", "query_netscape",
      "query_node", "query_origin", "query_stamp", "query_udat", "query_windows",
      "receive_message", "redirect_to", "respond", "respond_to_request",
      "restore_zsession_data", "send_entity_headers", "send_file", "send_headers",
      "send_html", "set_node", "set_origin", "start_auth", "state", "state_body", "state_headers",
      "state_responding", "state_virgin", "url_absolute" ], sf.func_decls.keys.sort
  end

end
