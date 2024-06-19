require "active_support/concern"

module Railcutters
  module ActiveRecord
    module Pagination
      extend ActiveSupport::Concern

      module RelationMethods
        attr_reader :pagination

        def paginated?
          @pagination.present?
        end
      end

      # Configure the pagination options for a model using the following DSL.
      # Example:
      #
      # ```
      # class User < ApplicationRecord
      #   paginates_per 100
      # end
      # ```
      class_methods do
        # Specify a maximum per_page value per each model. If the variable that specified via per
        # scope is more than this variable, max_paginates_per is used instead of it.
        #
        # Default value is 100
        def max_paginates_per(amount)
          @max_paginates_per = amount
        end

        # Specify max_pages value per each model. This value restricts the total number of pages
        # that can be returned.
        # Useful for setting limits on large collections.
        #
        # Default value is 100
        def max_pages(amount)
          @max_pages = amount
        end

        # Sets the default number of records per page.
        #
        # Default value is 30, the limit is set by `max_paginates_per`
        def paginates_per(amount)
          @paginates_per = amount
        end

        # Defines the columns that can be used to sort a query using the `user_sort` scope.
        #
        # It takes either a list of columns or an array. Defaults to an empty array
        def user_sort_columns(*columns)
          @user_sort_columns = columns.flatten.compact_blank
        end
      end

      included do
        # Sorts a query using the given field and direction. The field must be one of the columns
        # defined in the model using `user_sort_columns`.
        scope :user_sort, ->(field, direction = :asc) do
          next if field.blank?

          permitted_columns = klass.instance_variable_get(:@user_sort_columns)&.map(&:to_sym) || []
          next unless field.to_sym.in?(permitted_columns)

          direction = :asc unless %w[desc asc].include?(direction.to_sym)
          order(field.to_sym => direction.to_sym)
        end

        # Paginates a query using the the default per_page value
        scope :page, ->(page) do
          paginate(page: page)
        end

        # Paginates a query using the given page and per_page values
        #
        # If no page or per_page are given, it will use the defaults set on the model, and if none
        # is set, it will limit the results to 30 per page, and the number of pages to 100.
        #
        # You either use keyword arguments or a hash. Any query executed with this scope will have
        # the pagination metadata available on the resultset.
        scope :paginate, ->(*args, page: nil, per_page: nil) do
          if args[0] && !args[0].respond_to?(:keys)
            raise ArgumentError, "paginate expects a hash of keyword arguments"
          end
          args = args[0] || {}

          # Accept either a hash of a keyword param, but prefer the keyword param
          page ||= args[:page] || 1
          per_page ||= args[:per_page] || klass.instance_variable_get(:@paginates_per) || 30

          # To avoid user shenanigans, we validate the page and per_page values
          page = page.to_i
          per_page = per_page.to_i
          page = 1 if page < 1
          max_pages = klass.instance_variable_get(:@max_pages) || 100
          page = [page, max_pages].min

          per_page = 30 if per_page < 1
          max_per_page = klass.instance_variable_get(:@max_paginates_per) || 100
          per_page = [per_page, max_per_page].min

          query = all

          # Get the total rows for the query
          total =
            if group_values.empty?
              # COUNT(*)
              count(:all)
            else
              # COUNT(*) OVER ()
              sql = Arel.star.count.over(Arel::Nodes::Grouping.new([]))
              unscope(:order).limit(1).pick(sql).to_i
            end

          pages = (total / per_page.to_f).ceil

          # Mark this query as paginated so we can retrieve the information later on the view
          query.instance_variable_set(:@pagination, {page:, per_page:, total:, pages:})

          # Run the order and limit/offset
          query.limit(per_page).offset((page - 1) * per_page).extending { include(RelationMethods) }
        end
      end
    end
  end
end
