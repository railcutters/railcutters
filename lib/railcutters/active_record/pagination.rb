require "active_record"

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
      end

      included do
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

          default_per_page = klass.instance_variable_get(:@paginates_per) || 30
          default_max_per_page = klass.instance_variable_get(:@max_paginates_per) || 100
          max_pages = klass.instance_variable_get(:@max_pages) || 100

          # Avoid shooting oneself in the foot. When explicitly configuring the default value for
          # paginates_per in the model, make sure it's at least the same as the max_paginates_per,
          # otherwise it will be ignored.
          klass_default_per_page = klass.instance_variable_get(:@paginates_per)
          if klass_default_per_page && klass_default_per_page > default_max_per_page
            default_max_per_page = klass_default_per_page
          end

          # Accept either a hash of a keyword param, but prefer the keyword param
          page ||= args[:page] || 1
          per_page ||= args[:per_page] || default_per_page

          # To avoid user shenanigans, we validate the page and per_page values
          page = page.to_i
          per_page = per_page.to_i
          page = 1 if page < 1
          page = [page, max_pages].min

          per_page = default_per_page if per_page < 1
          per_page = [per_page, default_max_per_page].min

          query = all

          # Get the total rows for the query
          total =
            if group_values.empty?
              # COUNT(*)
              count(:all)
            else
              # COUNT(*) OVER ()
              # Not supported on MySQL 5.7 and below (released in 2015)
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
