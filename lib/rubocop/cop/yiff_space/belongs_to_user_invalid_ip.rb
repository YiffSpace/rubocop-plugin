# frozen_string_literal: true

module RuboCop
  module Cop
    module YiffSpace
      # Detects when `ip:` is specified in a `belongs_to_user` call
      # but the corresponding IP address column does not exist in the database
      # schema. It auto-corrects by removing the invalid `ip:` option.
      #
      # @safety
      #   This cop reads the database schema to determine whether the column
      #   exists. It will not flag anything if the schema cannot be loaded.
      #
      # @example
      #   # bad - no `creator_ip_addr` column exists in the schema
      #   belongs_to_user(:creator, ip: true)
      #
      #   # bad - no `creator_custom` column exists in the schema
      #   belongs_to_user(:creator, ip: "creator_custom")
      #
      #   # good
      #   belongs_to_user(:creator)
      #
      #   # good - `creator_ip_addr` column exists in the schema
      #   belongs_to_user(:creator, ip: true)
      #
      class BelongsToUserInvalidIp < Base
        extend(AutoCorrector)
        include(ActiveRecordHelper)
        include(NodeFormattingHelper)

        MSG = "`ip: %<ip_set>s` set for `belongs_to_user(%<attr>s)` when `%<ip_attr>s` column does not exist"

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
            return if [nil, "", false].include?(options[:ip])

            return unless schema

            table = table(node)
            return unless table

            column = options[:ip] == true ? "#{attr}_ip_addr" : options[:ip].to_s
            exists = table.with_column?(name: column)

            return if exists

            register_offense(node, attr, options, column, options[:ip])
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

        def register_offense(node, attr, options, column, original)
          message = format(MSG, attr: attr.inspect, ip_attr: "#{table(node).name}.#{column}".inspect,
                                ip_set: original.inspect)

          add_offense(node, message: message) do |corrector|
            new_options = format_new_options(attr, options)

            corrector.replace(node, "belongs_to_user(#{new_options})")
          end
        end

        def format_new_options(attr, options)
          list = [attr.inspect]

          options.delete(:ip)
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
