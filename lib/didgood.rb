require "DidGood/version"

require "json"
require "open-uri"

module DidGood
    class Error < StandardError; end

    def self.system_call(cmd)
        puts "Running command: #{cmd.inspect}..."
        system(cmd, out: $stdout, err: :out)
        unless $?.success?
            raise "Error running command: #{cmd.inspect}!"
        end
    end

    # This is a repo of everything DidGood saves between runs.
    # It includes downloaded Git repos, Goods files and more.
    class Repo
        attr_reader :didgood_dir

        def initialize
            @home = ENV["HOME"]
            @didgood_dir = "#{@home}/.didgood"
            Dir.mkdir(@didgood_dir) unless File.directory?(@didgood_dir)
            ["git", "goods"].each do |subdir|
                full_subdir = "#{@didgood_dir}/#{subdir}"
                Dir.mkdir(full_subdir) unless File.directory?(full_subdir)
            end
        end

        def git_repo(git_url)
            @git_repos ||= {}
            @git_repos[git_url] ||= GitRepo.new(self, git_url)
        end

        def didgood_file(path)
            raise "Already have a dgd.didgood file!" if @didgood_file

            @didgood_file ||= AppFile.new(self, path)
        end

        def assemble_app(location)
        end
    end

    # This is a DidGood-downloaded Git repo.
    # It can be a source for a GoodsSpec
    class GitRepo
        attr_reader :local_dir
        attr_reader :git_url

        def initialize(repo, git_url)
            @git_url = git_url
            @repo = repo
            local_path = git_url.tr("/\\", "_")
            @local_dir = "#{@repo.didgood_dir}/git/#{local_path}"

            if File.directory?(@local_dir)
                Dir.chdir(@local_dir) do
                    DidGood.system_call("git pull")
                end
            else
                DidGood.system_call("git clone #{@git_url} #{@local_dir}")
            end
        end
    end

    class AppFile
        attr_reader :path
        attr_reader :repo

        def initialize(repo, path)
            @path = path
            @repo = repo
            raise("No such dgd.didgood file as #{path.inspect}!") unless File.exist?(path)
            contents = JSON.load(File.read(path))

            raise "Expected a top-level JSON array in dgd.didgood!" unless contents.is_a?(Array)

            @specs = contents.flat_map { |item| json_to_specs(item) }
            nil
        end

        def json_to_specs(item)
            raise "Expected every spec to be a JSON object, not #{item.inspect}!" unless item.is_a?(Hash)
            return [] if item.size == 0 || item.all? { |k, v| k == "" }

            if item["unbundled_goods"]
                raise "Unbundled_goods must have only one key!" unless item.size == 1

                return [unbundled_json_to_spec(item["unbundled_goods"])]
            end

            # A string-to-string mapping means a list of names and Goods URLs
            if item.is_a?(Hash) && item.all? { |k, v| k.is_a?(String) && v.is_a?(String) }
                return item.map do |name, goods_url|
                    begin
                        contents = JSON.parse(URI.open(goods_url).read)
                    rescue
                        STDERR.puts "Error reading or parsing by URL: #{goods_url.inspect}"
                        raise
                    end
                    unbundled_json_to_spec(contents)
                end
            end

            raise "Didn't recognize JSON objects as Goods specs in dgd.didgood!"
        end

        def unbundled_json_to_spec(fields)
            source = nil
            if fields["git"]
                raise "A git source requires a git url: #{fields.inspect}!" unless fields["git"]["url"]
                source = GitRepo.new(@repo, fields["git"]["url"])
            else
                raise "Didgood currently requires a Git-based source!"
            end

            spec = GoodsSpec.new(@repo, name: fields["name"], source: source, paths: fields["paths"])
            return spec
        end
    end

    class GoodsSpec
        attr_reader :repo
        attr_reader :name
        attr_reader :source
        attr_reader :paths

        def initialize(repo, name:, source:, paths:)
            @repo = repo
            @name = name
            @source = source
            @paths = paths
        end
    end
end
