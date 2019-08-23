module TrkDatatables
  class ActiveRecord < Base
    def filter_items(all)
      all
    end

    def order_and_paginate_items(filtered_items)
      filtered_items = order_items filtered_items
      filtered_items = filtered_items.offset(@dt_params.offset).limit(@dt_params.per_page)
      filtered_items
    end

    def order_items(filtered_items)
      return filtered_items if @dt_params.orders.blank?

      order_by = @dt_params.orders.each_with_object([]) do |order, queries|
        column_key, column_options = _get_column_key_and_column_options_by_index order[:column_index]
        raise TrkDatatables::Error, "Columns does not have element #{order[:column_index]}" unless column_key
        next if column_options[:order] == false

        queries << "#{column_key} #{order[:direction]}"
      end
      filtered_items.order(Arel.sql(order_by.join(', ')))
    end
  end
end
