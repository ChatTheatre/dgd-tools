require "DidGood/version"

require "json"
require "open-uri"
require "fileutils"

module DidGood
    class Error < StandardError; end

    DGD_BUILD_COMMAND = %(make DEFINES='-DUINDEX_TYPE="unsigned int" -DUINDEX_MAX=UINT_MAX -DEINDEX_TYPE="unsigned short" -DEINDEX_MAX=USHRT_MAX -DSSIZET_TYPE="unsigned int" -DSSIZET_MAX=1048576' install
)
    KERNEL_PATHS = ["/include/kernel", "/kernel"]
    DEFAULT_KERNELLIB_URL = "https://github.com/ChatTheatre/kernellib"

    GENERATED_ROOT = ".root"

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

            unless File.exist?("#{@didgood_dir}/dgd/bin/dgd")
                dgd_dir = "#{@didgood_dir}/dgd"
                if File.directory?(dgd_dir)
                    # Not clear to me what to do here...
                else
                    DidGood.system_call("git clone https://github.com/ChatTheatre/dgd.git #{dgd_dir}")
                    Dir.chdir("#{@didgood_dir}/dgd/src") do
                        DidGood.system_call(DGD_BUILD_COMMAND)
                    end
                end
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
            dgd_root = "#{File.expand_path(location)}/#{GENERATED_ROOT}"
            app_path = "#{File.expand_path(location)}/#{@didgood_file.app_root}"
            FileUtils.rm_rf(dgd_root)
            FileUtils.cp_r(app_path, dgd_root)

            write_config_file("#{location}/dgd.config")
            specs = @didgood_file.specs

            specs.each do |spec|
                git_repo = spec.source
                git_repo.use_details(spec.source_details)

                spec.paths.each do |from, to|
                    from_path = "#{git_repo.local_dir}/#{from}"
                    to_path = "#{dgd_root}/#{to}"
                    FileUtils.mkdir_p to_path
                    FileUtils.cp_r(from_path, to_path)
                end
            end
        end

        def write_config_file(path)
            File.open(path, "wb") do |f|
                f.write <<CONTENTS
/* These are SkotOS limits. They are enormous. They should
   be configurable but they are not yet. */
telnet_port = ([
    "*":50100  /* telnet port number */
]);
binary_port = ([
    "*":50110, /* Failsafe */
]);   /* binary ports */
directory = "./#{GENERATED_ROOT}";

users       = 100;           /* max # of users */
editors     = 40;           /* max # of editor sessions */
ed_tmpfile  = "../state/ed";        /* proto editor tmpfile */
swap_file   = "../state/swap";  /* swap file */
swap_size   = 1048576;         /* # sectors in swap file */
sector_size = 512;          /* swap sector size */
swap_fragment   = 4096;           /* fragment to swap out */
static_chunk    = 64512;        /* static memory chunk */
dynamic_chunk   = 261120;       /* dynamic memory chunk */
dump_file   = "../state/dump";  /* dump file */
dump_interval   = 3600;             /* dump interval */

typechecking    = 2;            /* highest level of typechecking */
include_file    = "/include/std.h";     /* standard include file */
include_dirs    = ({ "/include", "~/include" }); /* directories to search */
auto_object     = "/kernel/lib/auto";   /* auto inherited object */
driver_object   = "/kernel/sys/driver"; /* driver object */
create      = "_F_create";      /* name of create function */

array_size  = 16384;         /* max array size */
objects     = 262144;          /* max # of objects */
call_outs   = 16384;          /* max # of call_outs */
CONTENTS
            end
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
                    DidGood.system_call("git checkout #{default_branch} && git pull")
                end
            else
                DidGood.system_call("git clone #{@git_url} #{@local_dir}")
            end
        end

        def default_branch
            return @default_branch if @default_branch
            output = `git rev-parse --abbrev-ref origin/HEAD`.chomp
            @default_branch = output.gsub(/^origin\//, "")
        end

        def use_details(details)
            if details["branch"]
                Dir.chdir(@local_dir) do
                    DidGood.system_call("git checkout #{details["branch"]}")
                end
            else
                Dir.chdir(@local_dir) do
                    DidGood.system_call("git checkout #{default_branch}")
                end
            end
        end
    end

    class AppFile
        attr_reader :path
        attr_reader :repo
        attr_reader :specs
        attr_reader :app_root

        def initialize(repo, path)
            @path = path
            @repo = repo
            raise("No such dgd.didgood file as #{path.inspect}!") unless File.exist?(path)
            contents = JSON.load(File.read(path))

            read_didgood_file(contents)

            @app_root = contents["app_root"] || "app"

            paths = @specs.flat_map { |s| s.paths }
            unless paths == paths.uniq
                repeated_paths = paths.select { |p| paths.count(p) > 1 }
                raise "Repeated (conflicting?) paths in dgd.didgood! #{repeated_paths.inspect}"
            end

            # Make sure the dgd.didgood file overrides either no kernel paths or both/all
            if KERNEL_PATHS.any? { |kp| paths.include?(kp) }
                unless KERNEL_PATHS.all? { |kp| paths.include?(kp) }
                    raise "dgd.didgood file #{path.inspect} includes some Kernel Library paths but not all! All needed: #{KERNEL_PATHS}!"
                end
                puts "This dgd.didgood file overrides the Kernel Library with its own."
            else
                # This app has specified no kernellib paths -- add them
                git_repo = @repo.git_repo(DEFAULT_KERNELLIB_URL)
                kl_paths = { "src/kernel" => "/kernel", "src/include/kernel" => "/include/kernel", "src/doc/kernel" => "/doc/kernel" }
                klib_spec = GoodsSpec.new @repo, name: "default Kernel Library",
                    source: git_repo, paths: kl_paths
                specs.push klib_spec
            end

            nil
        end

        def read_didgood_file(contents)
            raise "Expected a top-level JSON object in dgd.didgood!" unless contents.is_a?(Hash)

            @specs = []

            if contents["unbundled_goods"]
                raise "Unbundled_goods must be an array!" unless contents["unbundled_goods"].is_a?(Array)

                @specs += contents["unbundled_goods"].map { |item| unbundled_json_to_spec(item) }
            end

            if contents["goods"]
                raise "Goods must be an array!" unless contents["goods"].is_a?(Array)

                @specs += contents["goods"].map do |goods_url|
                    begin
                        json_contents = JSON.parse(URI.open(goods_url).read)
                    rescue
                        STDERR.puts "Error reading or parsing by URL: #{goods_url.inspect}"
                        raise
                    end
                    unbundled_json_to_spec(json_contents)
                end
            end
        end

        def unbundled_json_to_spec(fields)
            source = nil
            source_details = nil
            if fields["git"]
                raise "A git source requires a git url: #{fields.inspect}!" unless fields["git"]["url"]
                source = @repo.git_repo(fields["git"]["url"])
                source_details = fields["git"]  # May contain branch info, etc.
            else
                raise "Didgood currently requires a Git-based source!"
            end

            unless fields["paths"].all? { |k, v| k.is_a?(String) && v.is_a?(String) }
                raise "Paths in Goods files must map strings to strings! #{fields["paths"].inspect}"
            end

            spec = GoodsSpec.new(@repo, name: fields["name"], source: source, source_details: source_details, paths: fields["paths"])
            return spec
        end
    end

    class GoodsSpec
        attr_reader :repo
        attr_reader :name
        attr_reader :source
        attr_reader :source_details
        attr_reader :paths

        def initialize(repo, name:, source:, source_details: {}, paths:)
            @repo = repo
            @name = name
            @source = source
            @source_details = source_details
            @paths = paths
        end
    end
end
