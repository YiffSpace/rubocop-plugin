# frozen_string_literal: true

module RuboCop
  module Cop
    module YiffSpace
      # Detects when a `belongs_to_user` call is missing `ip: true`
      # even though a corresponding `<attr>_ip_addr` column exists in the
      # database schema. It auto-corrects by adding `ip: true`.
      #
      # @safety
      #   This cop reads the database schema to determine whether the column
      #   exists. It will not flag anything if the schema cannot be loaded.
      #
      # @example
      #   # bad - `creator_ip_addr` column exists but `ip:` is not specified
      #   belongs_to_user(:creator)
      #
      #   # bad - `ip: false` explicitly opts out but the column exists
      #   belongs_to_user(:creator, ip: false)
      #
      #   # good
      #   belongs_to_user(:creator, ip: true)
      #
      #   # good - no `creator_ip_addr` column exists in the schema
      #   belongs_to_user(:creator)
      #
      class BelongsToUserMissingIp < Base
        extend(AutoCorrector)
        include(ActiveRecordHelper)
        include(NodeFormattingHelper)

        MSG = "Specify `ip: true` when a `belongs_to_user(%<attr>s)` relation has a corresponding `%<ip_attr>s` column"

        # requires_gem("activerecord")

        # @!method belongs_to_user?(node)
        def_node_matcher(:belongs_to_user?, <<~PATTERN)
          (send nil? :belongs_to_user $_ $...)
        PATTERN

        def on_send(node)
          belongs_to_user?(node) do |receiver, code|
            return unless receiver.type?(:str, :sym)

            attr = format_node(receiver)
            return if attr.nil? || attr.empty?

            options = format_node(code.last, {})
            return unless [nil, "", false].include?(options[:ip])

            return unless schema

            table = table(node)
            return unless table

            column = "#{attr}_ip_addr"
            exists = table.with_column?(name: column)

            return unless exists

            register_offense(node, attr, options, column)
          end
        end

        def on_csend(node)
          on_send(node)
        end

        private

        def class_node(node)
          node.each_ancestor.find(&:class_type?)
        end

        def table(node)
          klass = class_node(node)
          return unless klass

          schema.table_by(name: table_name(klass))
        end

        def register_offense(node, attr, options, column)
          message = format(MSG, attr: attr.inspect, ip_attr: column.inspect)

          add_offense(node, message: message) do |corrector|
            new_options = format_new_options(attr, options)

            corrector.replace(node, "belongs_to_user(#{new_options})")
          end
        end

        def format_new_options(attr, options)
          list = [attr.inspect, "ip: true"]

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
