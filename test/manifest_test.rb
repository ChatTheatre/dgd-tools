require "test_helper"

class DGDToolsTest < Minitest::Test
    def initialize(*args)
        super
        @test_dir = __dir__
        @data_dir = File.join(@test_dir, "data")
    end

    def test_that_it_has_a_version_number
        refute_nil ::DGD::VERSION
    end

    def with_repo_for_data_dir(subdir)
        Dir.chdir(File.join(@data_dir, subdir)) do
            repo = DGD::Manifest::Repo.new
            repo.manifest_file("dgd.manifest")
            yield(repo)
        end
    end

    def test_empty_precheck
        with_repo_for_data_dir("empty") { |repo| repo.precheck(".") }
    end

    def test_empty_repo_copies_no_files
        with_repo_for_data_dir("empty") do |repo|
            assert_equal [], repo.send(:assembly_operations, ".")
        end
    end

    def test_app_only_repo_copies_files
        with_repo_for_data_dir("app_only") do |repo|
            ops = repo.send(:assembly_operations, ".")
            assert_equal [
                {
                    :cmd => "cp",
                    :from => "#{@data_dir}/app_only/app",
                    :to => ".",
                    :dirs => [ "#{@data_dir}/app_only/app/a_dir" ],
                    :non_dirs => [ "#{@data_dir}/app_only/app/file_1" ]
                },
            ], ops
        end
    end
end
