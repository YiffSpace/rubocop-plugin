# frozen_string_literal: true

module RuboCop
  module Cop
    module YiffSpace
      # Prevents use of the CurrentUser class outside of the request
      # cycle. CurrentUser relies on thread-local state set by request
      # middleware and is unavailable in background jobs, rake tasks, or other
      # contexts outside of the request lifecycle.
      #
      # The class name is configurable via `ClassName` (default: `CurrentUser`).
      # References inside the class that defines CurrentUser itself are always
      # ignored. Controllers, views, helpers, presenters, and decorators are
      # excluded by default. Use `IgnoredMethods`, `IgnoredMethodPrefixes`,
      # `IgnoredMethodSuffixes`, or `IgnoredMethodPatterns` to allow
      # CurrentUser in specific methods in checked files.
      #
      # @example
      #   # bad
      #   def process_records
      #     CurrentUser.id
      #   end
      #
      #   # bad
      #   def notify
      #     CurrentUser.email
      #   end
      #
      #   # good - inside the CurrentUser class definition itself
      #   class CurrentUser
      #     def self.id
      #       RequestStore[:current_user]&.id
      #     end
      #   end
      #
      #   # good (IgnoredMethodSuffixes: [_current])
      #   def user_current
      #     CurrentUser.id
      #   end
      #
      #   # good (IgnoredMethodPrefixes: [apionly_])
      #   def apionly_serialize
      #     CurrentUser.email
      #   end
      #
      #   # good (IgnoredMethodPatterns: [/_current_user_/])
      #   def serialize_current_user_email
      #     CurrentUser.email
      #   end
      #
      class CurrentUserOutsideOfRequests < Base
        MSG = "`%<class_name>s` should only be used within the request cycle (controllers, views, helpers, decorators)"

        def on_send(node)
          return unless starts_with_current_user?(node)
          return if ignored_method?(node)
          return if inside_current_user_class?(node)

          add_offense(node, message: message)
        end

        def on_csend(node)
          on_send(node)
        end

        def on_const(node)
          return unless current_user?(node)
          return if ignored_method?(node)
          return if inside_current_user_class?(node)
          return if node.parent&.send_type? && node.parent.receiver == node

          add_offense(node, message: message)
        end

        private

        def message
          format(MSG, class_name: current_user_class_name)
        end

        def current_user_class_name
          cop_config.fetch("ClassName", "CurrentUser")
        end

        def current_user?(node)
          return false unless node.const_type?

          class_parts = current_user_class_name.split("::")
          is_absolute, ref_parts = extract_const_info(node)

          return ref_parts == class_parts if is_absolute

          return false if ref_parts.length > class_parts.length
          return false unless class_parts.last(ref_parts.length) == ref_parts

          expected_ns = class_parts.first(class_parts.length - ref_parts.length)

          ancestors = node.each_ancestor(:module, :class).to_a.reverse
          cumulative = []
          idx = 0
          inner_ancestors = []

          ancestors.each do |anc|
            parts = const_parts(anc.identifier)
            inner_ancestors << anc if idx + parts.length > expected_ns.length
            cumulative.concat(parts)
            idx += parts.length
          end

          return false unless cumulative.first(expected_ns.length) == expected_ns

          inner_ancestors.none? { |anc| defines_const_in_body?(anc, ref_parts[0]) }
        end

        def starts_with_current_user?(node)
          node.receiver && current_user?(node.receiver)
        end

        def inside_current_user_class?(node)
          node.each_ancestor(:class).any? do |class_node|
            resolved_class_name(class_node) == current_user_class_name
          end
        end

        def resolved_class_name(class_node)
          parts = const_parts(class_node.identifier)
          class_node.each_ancestor(:module, :class) { |ancestor| parts = const_parts(ancestor.identifier) + parts }
          parts.join("::")
        end

        def const_parts(const_node)
          parts = []
          node = const_node
          while node&.const_type?
            parts.unshift(node.short_name.to_s)
            node = node.namespace
          end
          parts
        end

        def extract_const_info(node)
          parts = []
          current = node
          while current&.const_type?
            parts.unshift(current.short_name.to_s)
            current = current.namespace
          end
          [current&.cbase_type? || false, parts]
        end

        def defines_const_in_body?(scope_node, name)
          scope_node.body&.each_child_node(:class, :module)&.any? do |child|
            child.identifier.short_name.to_s == name
          end
        end

        def ignored_method?(node)
          enclosing_method = node.each_ancestor(:any_def).first

          return false unless enclosing_method&.any_def_type?

          method_name = enclosing_method.method_name.to_s
          ignored.any? { |pattern| pattern.match?(method_name) }
        end

        def ignored
          @ignored ||= begin
            pattern = ignored_patterns
            prefix = ignored_prefixes.map { |p| Regexp.new("^#{p}") }
            suffix = ignored_suffixes.map { |p| Regexp.new("#{p}$") }
            methods = ignored_methods.map { |p| Regexp.new("^#{p}$") }
            [*pattern, *prefix, *suffix, *methods]
          end
        end

        def ignored_patterns
          @ignored_patterns ||= Array(cop_config["IgnoredMethodPatterns"]).map { |p| Regexp.new(p) }
        end

        def ignored_prefixes
          @ignored_prefixes ||= Array(cop_config["IgnoredMethodPrefixes"])
        end

        def ignored_suffixes
          @ignored_suffixes ||= Array(cop_config["IgnoredMethodSuffixes"])
        end

        def ignored_methods
          @ignored_methods ||= Array(cop_config["IgnoredMethods"])
        end
      end
    end
  end
end
