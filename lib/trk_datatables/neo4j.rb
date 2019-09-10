module TrkDatatables
  class Neo4j < Base
    def filter_by_search_all(filtered)
      filtered
    end

    def filter_by_columns(all)
      all
    end

    def order_and_paginate_items(filtered)
      filtered = order_items filtered
      filtered = filtered.offset(@dt_params.dt_offset).limit(dt_per_page_or_default)
      filtered
    end

    def order_items(filtered)
      filtered
    end
  end
end
