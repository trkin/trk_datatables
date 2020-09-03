module TrkDatatables
  class ActiveRecord < Base
    # Global search. All columns are typecasted to string. Search string is
    # splited by space and "and"-ed.
    def filter_by_search_all(filtered)
      conditions = @dt_params.search_all.split(' ').map do |search_string|
        @column_key_options.searchable_and_global_search.map do |column_key_option|
          filter_column_as_string column_key_option, search_string
        end.reduce(:or) # any searchable column is 'or'-ed
      end.reduce(:and) # 'and' for each search_string

      filtered.where conditions
    end

    def filter_by_columns(filtered)
      conditions = @dt_params.dt_columns.each_with_object([]) do |dt_column, cond|
        next unless dt_column[:searchable] && dt_column[:search_value].present?

        # check both params and configuration
        column_key_option = @column_key_options[dt_column[:index]]
        next if column_key_option[:column_options][ColumnKeyOptions::SEARCH_OPTION] == false

        cond << build_condition_for_column(column_key_option, dt_column[:search_value])
      end.reduce(:and) # 'and' for each searchable column

      filtered.where conditions
    end

    def build_condition_for_column(column_key_option, search_value)
      # nil is when we use action columns, usually not column searchable
      return nil if column_key_option[:column_type_in_db].nil?

      select_options = column_key_option[:column_options][ColumnKeyOptions::SELECT_OPTIONS]
      if select_options.present?
        filter_column_as_in(column_key_option, search_value)
      elsif %i[boolean].include?(column_key_option[:column_type_in_db])
        filter_column_as_boolean(column_key_option, search_value)
      elsif %i[date datetime integer float].include?(column_key_option[:column_type_in_db]) && \
            search_value.include?(BETWEEN_SEPARATOR)
        from, to = search_value.split BETWEEN_SEPARATOR
        filter_column_as_between(column_key_option, from, to)
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

    def filter_column_as_boolean(column_key_option, search_value)
      # return true relation in case we ignore
      return Arel::Nodes::SqlLiteral.new('1').eq(1) if search_value == 'any'

      _arel_column(column_key_option).eq(search_value == 'true')
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
        # nil will result in true relation
      end
    end

    def filter_column_as_in(column_key_option, search_value)
      _arel_column(column_key_option).in search_value.split(MULTIPLE_OPTION_SEPARATOR)
    end

    def _parse_from_to(from, to, column_key_option)
      case column_key_option[:column_type_in_db]
      when :integer, :float
        # we do not need to cast from string since range will do automatically
        parsed_from = from
        parsed_to = to
      when :date, :datetime
        parsed_from = _parse_in_zone(from)
        parsed_to = _parse_in_zone(to)
        if parsed_to.present? && !to.match(/AM|PM/)
          # we need to add one day since it looks at begining of a day 2010-10-10 00:00:00
          parsed_to += 60 * 60 * 24 - 1
        end
      end
      [parsed_from, parsed_to]
    end

    def _parse_in_zone(time)
      return nil if time.blank?

      # without zone we will parse without zone so make sure params are correct
      Time.zone ? Time.zone.parse(time) : Time.parse(time)
    rescue ArgumentError
      nil
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
      filtered.order(Arel.sql(order_by.join(', ')))
    end

    def _arel_column(column_key_option)
      if column_key_option[:table_class] < TrkDatatables::CalculatedInDb
        Arel.sql send(column_key_option[:column_key])
      else
        column_key_option[:table_class].arel_table[column_key_option[:column_name]]
      end
    end
  end
end
