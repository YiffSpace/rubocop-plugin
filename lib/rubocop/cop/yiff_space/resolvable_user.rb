# frozen_string_literal: true

module RuboCop
  module Cop
    module YiffSpace
      # Detects `resolvable` calls that should instead use
      # `belongs_to_user` because the corresponding `<attr>_id` column exists
      # in the database schema. It auto-corrects to `belongs_to_user`, adding
      # `ip: true` when a `<attr>_ip_addr` column also exists.
      #
      # @safety
      #   This cop reads the database schema to determine whether the columns
      #   exist. It will not flag anything if the schema cannot be loaded.
      #   `belongs_to_user` must be defined in the target codebase.
      #
      # @example
      #   # bad - `creator_id` column exists in the schema
      #   resolvable(:creator)
      #
      #   # good
      #   belongs_to_user(:creator)
      #
      #   # bad - `creator_id` and `creator_ip_addr` columns exist in the schema
      #   resolvable(:creator)
      #
      #   # good
      #   belongs_to_user(:creator, ip: true)
      #
      class ResolvableUser < Base
        extend(AutoCorrector)
        include(ActiveRecordHelper)
        include(NodeFormattingHelper)

        MSG = "use `belongs_to_user(%<attr>s)` when `%<id_column>s` column exists"
        MSG_IP = "use `belongs_to_user(%<attr>s, ip: true)` when `%<id_column>s` and `%<ip_column>s` columns exist"

        # @!method resolvable?(node)
        def_node_matcher(:resolvable?, <<~PATTERN)
          (send nil? :resolvable $_ $...)
        PATTERN

        def on_send(node)
          resolvable?(node) do |receiver, code|
            return unless receiver.type?(:str, :sym)

            attr = format_node(receiver)
            return if attr.nil? || attr.empty?

            options = format_node(code.last, {})

            return unless schema

            table = table(node)
            return unless table

            column = "#{attr}_id"
            ip_column = "#{attr}_ip_addr"
            exists = table.with_column?(name: column)
            ip_exists = table.with_column?(name: ip_column)

            return unless exists

            options[:ip] = true if ip_exists

            register_offense(node, attr, options, column, ip_column)
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

        def register_offense(node, attr, options, id_column, ip_column)
          message = if options[:ip]
                      format(MSG_IP, attr: attr.inspect, id_column: id_column.inspect, ip_column: ip_column.inspect)
                    else
                      format(MSG, attr: attr.inspect, id_column: id_column.inspect)
                    end

          add_offense(node, message: message) do |corrector|
            new_options = format_new_options(attr, options)

            corrector.replace(node, "belongs_to_user(#{new_options})")
          end
        end

        def format_new_options(attr, options)
          list = [attr.inspect]

          if options.any?
            options.slice(:ip, :clone).merge(options.except(:ip, :clone)).each do |k, v|
              list << "#{k}: #{v.inspect}"
            end
          end
          list.join(", ")
        end
      end
    end
  end
end
