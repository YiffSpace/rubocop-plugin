# frozen_string_literal: true

require("lint_roller")

module RuboCop
  module YiffSpace
    # A plugin that integrates rubocop-yiffspace with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name:        "rubocop-yiffspace",
          version:     VERSION,
          homepage:    "https://github.com/YiffSpace/rubocop-plugin",
          description: "Shared rubocop rules for YiffSpace",
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type:          :path,
          config_format: :rubocop,
          value:         Pathname.new(__dir__).join("../../../config/default.yml"),
        )
      end
    end
  end
end
