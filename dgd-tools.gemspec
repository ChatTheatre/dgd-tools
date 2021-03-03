require_relative 'lib/dgd-tools/version'

Gem::Specification.new do |spec|
  spec.name          = "dgd-tools"
  spec.version       = DGD::VERSION
  spec.authors       = ["Noah Gibbs"]
  spec.email         = ["the.codefolio.guy@gmail.com"]

  spec.summary       = %q{dgd-tools supplies DGD tools -- like the DGD Manifest library system -- via a Ruby gem.}
  spec.description   = %q{dgd-tools supplies DGD Manifest and eventually perhaps other tools. DGD Manifest is an experimental DGD library and packaging system.}
  spec.homepage      = "https://github.com/noahgibbs/dgd-tools"
  spec.license       = "AGPL"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nokogiri", "~>1.10.5"
  spec.add_runtime_dependency "optimist", "~>3.0.1"
end
