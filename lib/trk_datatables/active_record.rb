module TrkDatatables
  class ActiveRecord < Base
    # Global search. All columns are typecasted to string. Search string is
    # splited by space and "and"-ed.
    def filter_by_search_all(filtered_items)
      conditions = @dt_params.search_all.split(' ').inject([]) do |cond, search_string|
        type_cast = @column_key_options.global_search_type_cast
        cond << @column_key_options.searchable.map do |column_key_option|
          casted_column = ::Arel::Nodes::NamedFunction.new(
            'CAST', [
              column_key_option[:table_class].arel_table[column_key_option[:column_name]].as(type_cast)
            ]
          )
          casted_column.matches("%#{search_string}%")
        end.reduce(:or)
      end.compact.reduce(:and)

      filtered_items.where conditions
    end

    def filter_by_columns(filtered_items)
      filtered_items
    end

    def order_and_paginate_items(filtered_items)
      filtered_items = order_items filtered_items
      filtered_items = filtered_items.offset(@dt_params.offset).limit(@dt_params.per_page)
      filtered_items
    end

    def order_items(filtered_items)
      return filtered_items if @dt_params.orders.blank?

      order_by = @dt_params.orders.each_with_object([]) do |order, queries|
        column_key_option = @column_key_options[order[:column_index]]
        next if column_key_option[:column_options][:order] == false

        queries << "#{column_key_option[:column_key]} #{order[:direction]}"
      end
      filtered_items.order(Arel.sql(order_by.join(', ')))
    end
  end
end
