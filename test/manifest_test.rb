require "test_helper"

class DGDToolsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DGD::VERSION
  end

  def test_it_does_something_useless
    assert true
  end

  def test_empty_precheck
    Dir.chdir(File.join(__dir__, "data", "empty")) do
      repo = DGD::Manifest::Repo.new
      repo.manifest_file("dgd.manifest")
      repo.precheck(".")
    end
  end
end
