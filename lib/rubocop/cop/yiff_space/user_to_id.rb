# frozen_string_literal: true

module RuboCop
  module Cop
    module YiffSpace
      # Detects the ternary pattern `x.is_a?(User) ? x.id : x` and
      # enforces use of the `u2id` helper instead, which handles both User
      # objects and raw IDs without the inline type check.
      #
      # @safety
      #   `u2id` must be defined in the target codebase. The auto-correct is
      #   safe when `u2id` accepts both User objects and integer IDs.
      #
      # @example
      #   # bad
      #   user.is_a?(User) ? user.id : user
      #
      #   # bad
      #   creator.is_a?(User) ? creator.id : creator
      #
      #   # good
      #   u2id(user)
      #
      #   # good
      #   u2id(creator)
      #
      class UserToId < Base
        extend(AutoCorrector)
        include(NodeFormattingHelper)

        MSG = "Use `u2id(%<var>s)` instead of `%<original>s`"

        def on_if(node)
          return unless node.ternary?

          return unless user_check?(node.condition)
          return unless id_call?(node.if_branch)
          return unless same_value?(node.if_branch.receiver, node.else_branch)

          message = format(MSG, var: node.else_branch.source, original: node.source)
          add_offense(node, message: message) do |corrector|
            corrector.replace(node, "u2id(#{node.else_branch.source})")
          end
        end

        private

        def user_check?(node)
          node&.send_type? &&
            node.method?(:is_a?) &&
            node.first_argument&.const_name == "User"
        end

        def id_call?(node)
          node&.send_type? && node.method?(:id)
        end

        def same_value?(a, b)
          a && b && a.source == b.source
        end
      end
    end
  end
end
