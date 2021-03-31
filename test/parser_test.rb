require "test_helper"
require "dgd-tools/dgd-doc"

class DGDParserTest < Minitest::Test
    def initialize(*args)
        super
        @test_dir = __dir__
        @dgd_source_dir = File.join(@test_dir, "dgd_source")
    end

    def test_that_it_has_a_version_number
        refute_nil ::DGD::VERSION
    end

end
