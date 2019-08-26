module TrkDatatables
  class ActiveRecord < Base
    # Global search. All columns are typecasted to string. Search string is
    # splited by space and "and"-ed.
    def filter_by_search_all(filtered_items)
      conditions = @dt_params.search_all.split(' ').map do |search_string|
        @column_key_options.searchable.map do |column_key_option|
          filter_column_as_string column_key_option, search_string
        end.reduce(:or) # any searchable column is 'or'-ed
      end.reduce(:and) # 'and' for each search_string

      filtered_items.where conditions
    end

    def filter_by_columns(filtered_items)
      conditions = @dt_params.dt_columns.each_with_object([]) do |dt_column, cond|
        next unless dt_column[:searchable] && dt_column[:search_value].present?

        # check both params and configuration
        column_key_option = @column_key_options[dt_column[:index]]
        next if column_key_option[:column_options][ColumnKeyOptions::SEARCH_OPTION] == false

        cond << build_condition_for_column(column_key_option, dt_column[:search_value])
      end.reduce(:and) # 'and' for each searchable column

      filtered_items.where conditions
    end

    def build_condition_for_column(column_key_option, search_value)
      case column_key_option[:column_type_in_db]
      when :date, :datetime, :integer, :float
        if search_value.include? BETWEEN_SEPARATOR
          from, to = search_value.split BETWEEN_SEPARATOR
          filter_column_as_between(column_key_option, from, to)
        else
          filter_column_as_string(column_key_option, search_value)
        end
      else
        filter_column_as_string(column_key_option, search_value)
      end
    end

    def filter_column_as_string(column_key_option, search_value)
      search_value.split(' ').map do |search_string|
        casted_column = ::Arel::Nodes::NamedFunction.new(
          'CAST',
          [_arel_column(column_key_option).as(@column_key_options.string_cast)]
        )
        casted_column.matches("%#{search_string}%")
      end.reduce(:and)
    end

    def filter_column_as_between(column_key_option, from, to)
      from, to = _parse_from_to(from, to, column_key_option)
      if from.present? && to.present?
        _arel_column(column_key_option).between(from..to)
      elsif from.present?
        _arel_column(column_key_option).gteq(from)
      elsif to.present?
        _arel_column(column_key_option).lteq(to)
        # else
        # nil will reesult in true relation
      end
    end

    def _parse_from_to(from, to, column_key_option)
      case column_key_option[:column_type_in_db]
      # when :integer, :float
      # we do not need to cast from string since range will do automatically
      when :date, :datetime
        from = _parse_in_zone(from) if from.present?
        to = _parse_in_zone(to) if to.present?
      end
      [from, to]
    end

    # rubocop:disable Rails/TimeZone
    def _parse_in_zone(time)
      Time.zone ? Time.zone.parse(time) : Time.parse(time)
    end
    # rubocop:enable Rails/TimeZone

    def order_and_paginate_items(filtered_items)
      filtered_items = order_items filtered_items
      filtered_items = filtered_items.offset(@dt_params.offset).limit(@dt_params.per_page)
      filtered_items
    end

    def order_items(filtered_items)
      return filtered_items if @dt_params.dt_orders.blank?

      order_by = @dt_params.dt_orders.each_with_object([]) do |dt_order, queries|
        column_key_option = @column_key_options[dt_order[:column_index]]
        next if column_key_option[:column_options][ColumnKeyOptions::ORDER_OPTION] == false

        queries << "#{column_key_option[:column_key]} #{dt_order[:direction]}"
      end
      filtered_items.order(Arel.sql(order_by.join(', ')))
    end

    def _arel_column(column_key_option)
      column_key_option[:table_class].arel_table[column_key_option[:column_name]]
    end
  end
end
