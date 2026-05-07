# frozen_string_literal: true

require_relative("lib/rubocop/yiff_space/version")

Gem::Specification.new do |spec|
  spec.name = "rubocop-yiffspace"
  spec.version = RuboCop::YiffSpace::VERSION
  spec.authors = ["Donovan_DMC"]
  spec.email = ["hewwo@yiff.rocks"]

  spec.summary = "Shared rubocop rules for YiffSpace"
  spec.description = spec.summary
  spec.homepage = "https://github.com/YiffSpace/rubocop-plugin"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.1"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["default_lint_roller_plugin"] = "RuboCop::YiffSpace::Plugin"

  spec.add_dependency("lint_roller", "~> 1.1")
  spec.add_dependency("rubocop", ">= 1.72.2")
end
