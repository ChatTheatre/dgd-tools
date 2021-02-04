require "test_helper"

class DGDToolsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DGD::VERSION
  end

  def with_repo_for_data_dir(subdir)
    Dir.chdir(File.join(__dir__, "data", subdir)) do
      repo = DGD::Manifest::Repo.new(no_write_homedir: true)
      repo.manifest_file("dgd.manifest")
      yield(repo)
    end
  end

  def test_empty_precheck
    with_repo_for_data_dir("empty") { |repo| repo.precheck(".") }
  end
end
