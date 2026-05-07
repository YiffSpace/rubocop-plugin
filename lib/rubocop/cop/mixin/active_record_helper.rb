# frozen_string_literal: true

begin
  require("rubocop-rails")
rescue LoadError
  module RuboCop
    module Cop
      module ActiveRecordHelper
        # Stub used when rubocop-rails is not available.
        # All schema-dependent cops guard on `return unless schema`, so
        # returning nil here causes them to skip silently.
        def schema
          nil
        end
      end
    end
  end
end
