require "active_support/concern"

module Railcutters
  module ActionController
    module Pagination
      extend ActiveSupport::Concern

      included do
        # Paginates a collection and sets the pagination result metadata on the response using the
        # Pagination header.
        #
        # Example response header:
        #
        # ```
        # Pagination: page=1,per-page=30,total-records=100,total-pages=4
        # ```
        #
        # smells of :reek:FeatureEnvy
        def paginate(collection, **overrides)
          pagination_params = params.permit(:page, :per_page)
          resultset = collection.paginate(pagination_params, **overrides)
          pagination = resultset.pagination

          headers["Pagination"] = [
            "page=#{pagination[:page]}",
            "per-page=#{pagination[:per_page]}",
            "total-records=#{pagination[:total]}",
            "total-pages=#{pagination[:pages]}"
          ].join(",")

          resultset
        end
      end
    end
  end
end
