require "active_support/concern"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/inclusion"

module Railcutters
  module ActiveRecord
    module SafeSort
      extend ActiveSupport::Concern

      # Configure the columns used to sort a query using the following DSL.
      # Example:
      #
      # ```
      # class User < ApplicationRecord
      #   safe_sortable_columns :name, "joined_table.subcolumn"
      # end
      # ```
      class_methods do
        # Defines the columns that can be used to sort a query using the `user_sort` scope.
        #
        # It takes either a list of columns or an array. Defaults to an empty array
        def safe_sortable_columns(*columns)
          @safe_sortable_columns = columns.flatten.compact_blank
        end
      end

      included do
        # Sorts a query using the given field and direction. The field must be one of the columns
        # defined in the model using `user_sort_columns`.
        scope :safe_sort, ->(field, direction = :asc, only_columns: [], default: nil, default_order: :asc) do
          next if field.blank?

          permitted_columns =
            only_columns.presence ||
            self.class.instance_variable_get(:@safe_sortable_columns)&.map(&:to_sym) ||
            []

          unless field.to_sym.in?(permitted_columns)
            if default.present?
              field = default
              direction = default_order
            else
              next
            end
          end

          direction = :asc unless direction.to_sym.in?(%i[desc asc])
          order(field.to_sym => direction.to_sym)
        end
      end
    end
  end
end
