# frozen_string_literal: true

module RuboCop
  module Cop
    module YiffSpace
      # Enforces using `belongs_to_user` instead of `belongs_to` for
      # User associations. `belongs_to_user` provides additional helper methods
      # and is the project standard for any relation backed by a User record.
      #
      # It matches both `belongs_to(:user)` and associations with an explicit
      # `class_name: "User"` option, auto-correcting both forms.
      #
      # The class name is configurable via `ClassName` (default: `User`).
      # The inferred attribute name is the snake_case of the last segment
      # (e.g. `ClassName: CurrentUser` matches `belongs_to(:current_user)`).
      #
      # @safety
      #   `belongs_to_user` must be defined in the target codebase, and the
      #   backing column must reference a User. Auto-correct is unsafe when
      #   either condition cannot be verified statically.
      #
      # @example
      #   # bad
      #   belongs_to(:user)
      #
      #   # bad
      #   belongs_to(:creator, class_name: "User")
      #
      #   # good
      #   belongs_to_user(:user)
      #
      #   # good
      #   belongs_to_user(:creator)
      #
      # @example ClassName: CurrentUser
      #   # bad
      #   belongs_to(:current_user, optional: false)
      #
      #   # bad
      #   belongs_to(:creator, class_name: "CurrentUser")
      #
      #   # good
      #   belongs_to_user(:current_user, optional: false)
      #
      #   # good
      #   belongs_to_user(:creator)
      #
      class BelongsToUser < Base
        extend(AutoCorrector)
        include(NodeFormattingHelper)

        MSG = "Use `belongs_to_user(%<attr>s)` instead of `belongs_to(%<attr>s)`"

        # requires_gem("activerecord")

        # @!method belongs_to_user?(node)
        def_node_matcher(:belongs_to_user?, <<~PATTERN)
          (send nil? :belongs_to $_ $...)
        PATTERN

        def on_send(node)
          belongs_to_user?(node) do |receiver, code|
            return unless receiver.type?(:str, :sym)

            attr = format_node(receiver)

            return if attr.nil? || attr.empty? || !code.last&.hash_type?

            options = format_node(code.last, {})

            # Match belongs_to(:user) (or configured attr name)
            if attr.to_sym == user_attr_name && !options.key?(:class_name)
              register_offense(node, attr, options)
              return
            end

            # Match belongs_to(attr, class_name: "User") (or configured ClassName)
            register_offense(node, attr, options) if options[:class_name] == user_class_name
          end
        end

        def on_csend(node)
          on_send(node)
        end

        private

        def register_offense(node, attr, options)
          message = format(MSG, attr: attr.inspect)

          add_offense(node, message: message) do |corrector|
            new_options = format_new_options(attr, options)

            corrector.replace(node, "belongs_to_user(#{new_options})")
          end
        end

        def user_class_name
          cop_config.fetch("ClassName", "User")
        end

        def user_attr_name
          last_segment = user_class_name.split("::").last
          last_segment.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
        end

        def format_new_options(attr, options)
          list = [attr.inspect]

          options.delete(:class_name)
          if options.any?
            options.each do |k, v|
              list << "#{k}: #{v.inspect}"
            end
          end
          list.join(", ")
        end
      end
    end
  end
end
