require "dgd-tools/version"

require "json"
require "open-uri"
require "fileutils"

module DGD; end

module DGD::Manifest
    DGD_BUILD_COMMAND = %(make DEFINES='-DUINDEX_TYPE="unsigned int" -DUINDEX_MAX=UINT_MAX -DEINDEX_TYPE="unsigned short" -DEINDEX_MAX=USHRT_MAX -DSSIZET_TYPE="unsigned int" -DSSIZET_MAX=1048576' install
)
    KERNEL_PATH_MAP = {
        "src/kernel" => "/kernel",
        "src/include" => "/include",
        "src/doc/kernel" => "/doc/kernel"
    }
    KERNEL_PATHS = KERNEL_PATH_MAP.values
    DEFAULT_KERNELLIB_URL = "https://github.com/ChatTheatre/kernellib"
    GENERATED_ROOT = ".root"

    def self.system_call(cmd)
        puts "Running command: #{cmd.inspect}..."
        system(cmd, out: $stdout, err: :out)
        unless $?.success?
            raise "Error running command: #{cmd.inspect}!"
        end
    end

    # This is a repo of everything DGD Manifest saves between runs.
    # It includes downloaded Git repos, Goods files and more.
    class Repo
        attr_reader :shared_dir

        def initialize
            @no_manifest_file = true
            @home = ENV["HOME"]
            @shared_dir = "#{@home}/.dgd-tools"
            Dir.mkdir(@shared_dir) unless File.directory?(@shared_dir)

            ["git", "goods"].each do |subdir|
                full_subdir = "#{@shared_dir}/#{subdir}"
                Dir.mkdir(full_subdir) unless File.directory?(full_subdir)
            end

            unless File.exist?("#{@shared_dir}/dgd/bin/dgd")
                dgd_dir = "#{@shared_dir}/dgd"
                if File.directory?(dgd_dir)
                    # Not clear to me what to do here...
                else
                    DGD::Manifest.system_call("git clone https://github.com/ChatTheatre/dgd.git #{dgd_dir}")
                    Dir.chdir("#{@shared_dir}/dgd/src") do
                        DGD::Manifest.system_call(DGD_BUILD_COMMAND)
                    end
                end
            end
        end

        def git_repo(git_url)
            @git_repos ||= {}
            @git_repos[git_url] ||= GitRepo.new(self, git_url)
        end

        def manifest_file(path)
            raise "Already have a dgd.manifest file!" unless @no_manifest_file

            @no_manifest_file = false
            @manifest_file ||= AppFile.new(self, path)
        end

        protected

        # This includes files to assemble... But also subdirectories and commands. This format is
        # unstable and ugly, and should not be exposed to outside parties who might later depend on it.
        def assembly_operations(location)
            operations = []

            raise("No manifest file!") if @no_manifest_file

            @manifest_file.specs.each do |spec|
                spec_git_repo = spec.source
                spec_git_repo.use_details(spec.source_details)  # This sets things like checked-out branch

                spec.paths.each do |from, to|
                    # Note: spec_git_repo.local_dir is an absolute path.
                    from_path = "#{spec_git_repo.local_dir}/#{from}"
                    if File.directory?(from_path)
                        files = Dir["#{from_path}/**/*"].to_a + Dir["#{from_path}/**/.*"].to_a
                        dirs = files.select { |file| File.directory?(file) }
                        non_dirs = files - dirs
                        operations << { cmd: "cp", from: from_path, to: to, dirs: dirs, non_dirs: non_dirs, comment: :single_dir }
                    elsif from_path["*"]  # If from_path contains at least one asterisk
                        components = from.split("/")
                        first_wild_idx = components.index { |item| item["*"] }
                        no_wild_from_path = components[0..(first_wild_idx-1)].join("/")
                        wild_path = components[first_wild_idx..-1].join("/")

                        files = Dir["#{spec_git_repo.local_dir}/#{no_wild_from_path}/#{wild_path}"].to_a
                        dirs = files.select { |file| File.directory?(file) }
                        dirs += files.map { |f| File.dirname(f) }
                        dirs.uniq!

                        non_dirs = files - dirs
                        operations << { cmd: "cp", from: "#{spec_git_repo.local_dir}/#{no_wild_from_path}", to: to, dirs: dirs, non_dirs: non_dirs, comment: :path_wildcard }
                    else
                        # A single file
                        operations << { cmd: "cp", from: from_path, to: to, dirs: [], non_dirs: [from_path], comment: :single_file }
                    end
                end
            end

            app_path = "#{File.expand_path(location)}/#{@manifest_file.app_root}"
            app_files = Dir["#{app_path}/**/*"].to_a
            app_dirs = app_files.select { |f| File.directory?(f) }
            app_non_dirs = app_files - app_dirs
            unless app_dirs.empty? && app_non_dirs.empty?
                operations << { cmd: "cp", from: app_path, to: ".", dirs: app_dirs, non_dirs: app_non_dirs, comment: :app_files }  # No source
            end

            operations
        end

        public

        def dgd_root(location)
            "#{File.expand_path(location)}/#{GENERATED_ROOT}"
        end

        def assemble_app(location)
            Dir[File.join(dgd_root(location), "*")].each { |dir| FileUtils.rm_rf dir }

            write_app_files(location)
        end

        def update_app(location)
            write_app_files(location)  # TODO: maybe check files dates? Some way to do update-only
        end

        protected

        def write_app_files(location)
            Dir.chdir(location) do
                write_config_file("#{location}/dgd.config")
                FileUtils.mkdir_p("#{location}/state") # Statedir for statedumps, editor files, etc.

                assembly_operations(location).each do |sd_hash|
                    to_path = "#{dgd_root(location)}/#{sd_hash[:to]}"

                    # Make appropriate dirs, including empty ones
                    sd_hash[:dirs].each do |dir|
                        FileUtils.mkdir_p dir.sub(sd_hash[:from], to_path)
                    end

                    # Copy all files
                    sd_hash[:non_dirs].each do |from_file|
                        to_file = from_file.sub(sd_hash[:from], "#{dgd_root(location)}/#{sd_hash[:to]}")
                        to_dir = File.dirname(to_file)
                        FileUtils.mkdir_p to_dir
                        FileUtils.cp from_file, to_file
                    end
                end
            end
        end

        public

        def precheck(location)
            all_files = assembly_operations(location).flat_map { |sd| sd[:non_dirs] }

            if all_files.size != all_files.uniq.size
                repeated = all_files.uniq.select { |f| all_files.count(f) > 1 }
                raise "Error in dgd.manifest! Repeated files: #{repeated.inspect} / #{all_files.inspect}"
            end
        end

        def write_config_file(path)
            File.open(path, "wb") do |f|
                f.write @manifest_file.dgd_config.as_file
            end
        end
    end

    # This is a Git repo managed by dgd-tools.
    # It can be a source for a GoodsSpec
    class GitRepo
        attr_reader :local_dir
        attr_reader :git_url

        def initialize(repo, git_url)
            @git_url = git_url
            @repo = repo
            local_path = git_url.tr("/\\", "_")
            @local_dir = "#{@repo.shared_dir}/git/#{local_path}"

            if File.directory?(@local_dir)
                Dir.chdir(@local_dir) do
                    DGD::Manifest.system_call("git checkout #{default_branch} && git pull")
                end
            else
                DGD::Manifest.system_call("git clone #{@git_url} #{@local_dir}")
            end
        end

        def default_branch
            @default_branch ||= `git rev-parse --abbrev-ref origin/HEAD`.chomp.gsub(/^origin\//, "")
        end

        def use_details(details)
            if details["branch"]
                Dir.chdir(@local_dir) do
                    DGD::Manifest.system_call("git checkout #{details["branch"]} && git pull")
                end
            else
                Dir.chdir(@local_dir) do
                    DGD::Manifest.system_call("git checkout #{default_branch} && git pull")
                end
            end
        end
    end

    class AppFile
        attr_reader :path
        attr_reader :repo
        attr_reader :specs
        attr_reader :dgd_config

        def initialize(repo, path)
            @path = path
            @repo = repo
            raise("No such dgd.manifest file as #{path.inspect}!") unless File.exist?(path)
            contents = AppFile.parse_manifest_file(path)

            read_manifest_file(contents)

            output_paths = @specs.flat_map { |s| s.paths.values }
            unless output_paths == output_paths.uniq
                repeated_paths = output_paths.select { |p| output_paths.count(p) > 1 }
                raise "Repeated (conflicting?) paths in dgd.manifest! #{repeated_paths.inspect}"
            end

            ## Make sure the dgd.manifest file overrides either no kernel paths or both/all
            #if KERNEL_PATHS.any? { |kp| output_paths.include?(kp) }
            #    unless KERNEL_PATHS.all? { |kp| output_paths.include?(kp) }
            #        raise "dgd.manifest file #{path.inspect} includes some Kernel Library paths but not all! All needed: #{KERNEL_PATHS}!"
            #    end
            #    puts "This dgd.manifest file overrides the Kernel Library with its own."
            #else
            #    puts "This dgd.manifest needs the default Kernel Library."
            #    # This app has specified no kernellib paths -- add them
            #    spec_git_repo = @repo.git_repo(DEFAULT_KERNELLIB_URL)
            #    klib_spec = GoodsSpec.new @repo, name: "default Kernel Library",
            #        source: spec_git_repo, paths: KERNEL_PATH_MAP
            #    specs.unshift klib_spec
            #end

            nil
        end

        # Load the JSON and then remove comments
        def self.parse_manifest_file(path)
            contents = JSON.parse(File.read path)
            remove_comments!(contents)
            contents
        end

        def self.remove_comments!(items)
            if items.is_a?(Hash)
                items.delete_if { |k, v| k[0] == "#" }
                items.values.each { |v| remove_comments!(v) }
            elsif items.is_a?(Array)
                items.delete_if { |i| i.is_a?(String) && i[0] == "#" }
                items.each { |i| remove_comments!(i) }
            end
        end

        def read_manifest_file(contents)
            raise "Expected a top-level JSON object in dgd.manifest!" unless contents.is_a?(Hash)

            @specs = []

            @dgd_config = DGDRuntimeConfig.new (contents["config"] || {})

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

        def app_root
            @dgd_config.app_root
        end

        def unbundled_json_to_spec(fields)
            source = nil
            source_details = nil
            if fields["git"]
                raise "A git source requires a git url: #{fields.inspect}!" unless fields["git"]["url"]
                source = @repo.git_repo(fields["git"]["url"])
                source_details = fields["git"]  # May contain branch info, etc.
            else
                raise "DGD Manifest currently requires a Git-based source!"
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

            cleaned_paths = {}
            paths.each do |k, v|
                # Remove leading and trailing slashes
                cleaned_paths[k.gsub(/^\//, "").chomp("/")] = v.gsub(/^\//, "").chomp("/")
            end

            @paths = cleaned_paths
        end
    end

    class AppDirectory
        attr_reader :location
        attr_accessor :name

        DEFAULT_FILE_LOCATIONS = {
            "manifest" => "dgd.manifest",
            "gitignore" => ".gitignore",
            "gems_rb" => "gems.rb",
        }
        DEFAULT_EMPTY_DIRS = [ "app", "state" ]

        def initialize(directory)
            @location = directory
        end

        def gitignore_contents
            <<~FILE_CONTENTS
                # DGD Manifest files
                .root
                dgd.config
                state/*
            FILE_CONTENTS
        end

        def manifest_contents
            <<FILE_CONTENTS
{
    "name": "#{@name}",
    "version": "0.1.0",
    "description": "TODO: put description here",
    "app_root": "app",
    "goods": [
        "# This is an example goods file - substitute your own.",
        "https://raw.githubusercontent.com/noahgibbs/dgd-tools/main/goods/skotos_httpd.goods"
    ],
    "unbundled_goods": [
        {
            "#": "this is an example of unbundled goods - substitute your own",
            "name": "kernellib",
            "git": {
                "url": "https://github.com/ChatTheatre/kernellib.git",
                "branch": "master"
            },
            "paths": {
                "src/doc/kernel": "doc/kernel",
                "src/include/kernel": "include/kernel",
                "src/include/*.h": "include",
                "src/kernel": "kernel"
            }
        }
    ]
}
FILE_CONTENTS
        end

        def gems_rb_contents
            <<~FILE_CONTENTS
                source "https://rubygems.org"

                gem "dgd-tools", ">= #{DGD::VERSION}"
            FILE_CONTENTS
        end

        def create!
            if File.exist?(@location) && (!File.directory?(@location) || Dir["#{@location}/**"].size != 0)
                raise "Cannot create a new DGD manifest project over a file or in an existing non-empty directory!"
            end

            puts "Creating new DGD manifest project at #{@location}..."
            FileUtils.mkdir_p @location
            Dir.chdir @location do
                DEFAULT_FILE_LOCATIONS.each do |file_desc, file_location|
                    File.open(file_location, "wb") do |f|
                        contents = send("#{file_desc}_contents")
                        f.write(contents)
                    end
                end

                DEFAULT_EMPTY_DIRS.each do |dir|
                    FileUtils.mkdir dir
                    FileUtils.touch File.join(dir, ".keep")
                end

                result = system "bundle"
                raise("Could not run bundler to install dgd-tools for #{@location}!") unless result

                result = system "bundle exec dgd-manifest install"
                raise("Error when running dgd-manifest for #{@location}!") unless result
            end

            puts "Successfully created project at #{@location}."
        end
    end

    class DGDRuntimeConfig
        attr_reader :app_root

        DEFAULT_CONFIG = {
                users: 100,
                editors: 40,
                swap_size: 1048576,
                sector_size: 512,
                swap_fragment: 4096,
                static_chunk: 64512,
                dynamic_chunk: 261120,
                dump_interval: 3600,
                typechecking: 2,
                include_file: "/include/std.h",
                include_dirs: ["/include", "~/include"],
                auto_object: "/kernel/lib/auto",
                driver_object: "/kernel/sys/driver",
                create: "_F_create",
                array_size: 16384,
                objects: 262144,
                call_outs: 16384,
            }
        CONFIG_KEYS = DEFAULT_CONFIG.keys.map(&:to_s) + [ "app_root", "ports", "telnet_ports", "dump_file", "statedir" ]

        def initialize(config_data)
            @app_root = config_data["app_root"] || "app"
            @ports = {
                "*" => 50100,
            }
            @telnet_ports = {
                "*" => 50110,
            }
            @statedir = config_data["statedir"] || "state"
            @dump_file = if config_data["dump_file"]
                    "../" + config_data["dump_file"]
                else
                    "../#{@statedir}/dump"
                end
            @config = DEFAULT_CONFIG.dup

            @raw_data = config_data
            @config.keys.each do |prop|
                # For now, assume and require that JSON data is the correct type if present
                @config[prop] = config_data[prop.to_s] if config_data[prop.to_s]
            end
            unexpected_config_keys = config_data.keys - CONFIG_KEYS
            unless unexpected_config_keys.empty?
                raise "Unexpected key names in DGD configuration: #{unexpected_config_keys.inspect}!"
            end

            if config_data["telnet_ports"]
                @telnet_ports = config_to_ports(config_data["telnet_ports"])
            end
            if config_data["ports"]
                @ports = config_to_ports(config_data["ports"])
            end
        end

        def config_to_ports(data)
            if data.is_a?(Hash)
                # TODO: verify that keys are IP addr strings and values are legal port numbers
                return data
            elsif data.is_a?(Array)
                # TODO: verify that data is an array of legal integer port numbers
                ports = {}
                data.each { |p| ports["*"] = p }
                return ports
            elsif data.is_a?(Integer)
                return { "*": data }
            else
                raise "dgd-manifest: not sure how to get port data from a #{data.class.name} -- #{data.inspect}!"
            end
        end

        def as_file
            return <<DGD_CONFIG
telnet_port = ([
    #{@telnet_ports.map { |ip, p| "#{ip.inspect}:#{p}" }.join(",\n    ") }
]);   /* legacy telnet ports */
binary_port = ([
    #{@ports.map { |ip, p| "#{ip.inspect}:#{p}" }.join(",\n    ") }
]);   /* binary ports */
directory       = "./#{GENERATED_ROOT}";

users           = #{@config[:users]}; /* max # of connections */
editors         = #{@config[:editors]}; /* max # of built-in-editor sessions */
ed_tmpfile      = "../#{@statedir}/ed"; /* proto editor tmpfile */
swap_file       = "../#{@statedir}/swap"; /* swap file */
swap_size       = #{@config[:swap_size]}; /* # sectors in swap file */
sector_size     = #{@config[:sector_size]}; /* swap sector size */
swap_fragment   = #{@config[:swap_fragment]}; /* fragment to swap out */
static_chunk    = #{@config[:static_chunk]}; /* static memory chunk */
dynamic_chunk   = #{@config[:dynamic_chunk]}; /* dynamic memory chunk */
dump_file       = #{@dump_file.inspect}; /* dump file */
dump_interval   = #{@config[:dump_interval]}; /* expected statedump interval in seconds */

typechecking    = #{@config[:typechecking]}; /* level of typechecking (2 is highest) */
include_file    = #{@config[:include_file].inspect}; /* standard include file */
include_dirs    = ({ #{@config[:include_dirs].map(&:inspect).join(", ")} }); /* directories to search */
auto_object     = #{@config[:auto_object].inspect}; /* auto inherited object */
driver_object   = #{@config[:driver_object].inspect}; /* driver object */
create          = #{@config[:create].inspect}; /* name of create function */

array_size      = #{@config[:array_size]}; /* max array size */
objects         = #{@config[:objects]}; /* max # of objects */
call_outs       = #{@config[:call_outs]}; /* max # of callouts */
DGD_CONFIG
        end
    end
end
