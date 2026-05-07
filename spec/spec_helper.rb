# frozen_string_literal: true

require("rubocop-yiffspace")
require("rubocop/rspec/support")

# Satisfy requires_gem("activerecord") checks in cops without loading the full gem.
Gem.loaded_specs["activerecord"] ||= Gem::Specification.new do |s|
  s.name = "activerecord"
  s.version = "8.0"
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand(config.seed)
end
