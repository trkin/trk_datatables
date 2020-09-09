module TrkDatatables
  class Neo4j < Base
    def filter_by_search_all(filtered)
      return filtered unless @dt_params.search_all.present?

      # https://neo4jrb.readthedocs.io/en/stable/QueryClauseMethods.html?highlight=where#where
      sql = @column_key_options.searchable_and_global_search.map do |column_key_option|
        "#{column_key_option[:column_key]} =~ ?"
      end.join(' or ')

      filtered.where sql, ".*#{@dt_params.search_all}.*"
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
      order_by = dt_orders_or_default_index_and_direction.each_with_object([]) do |(index, direction), queries|
        column_key_option = @column_key_options[index]
        next if column_key_option[:column_options][ColumnKeyOptions::ORDER_OPTION] == false

        queries << "#{column_key_option[:column_key]} #{direction}"
      end
      filtered.order(order_by.join(', '))
    end
  end
end
