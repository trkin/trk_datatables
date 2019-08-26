module TrkDatatables
  class ColumnKeyOptions
    # All options that you can use for columns:
    #
    # search: if you want to enable global and column search, default is true
    # order: `:asc` or `:desc` or `false`, default is `:desc`
    # @code
    #   def columns
    #     {
    #       'users.name': { search: false }
    #     }
    SEARCH_OPTION = :search
    # this will load date picker
    # SEARCH_OPTION_DATE_VALUE = :date
    # SEARCH_OPTION_DATETIME_VALUE = :datetime
    # this will load select
    SEARCH_OPTION_SELECT = :select
    SEARCH_OPTION_MULTISELECT = :multiselect
    SEARCH_OPTION_OPTIONS_FOR_SELECT = :options
    ORDER_OPTION = :order
    COLUMN_OPTIONS = [SEARCH_OPTION, ORDER_OPTION].freeze

    STRING_TYPE_CAST_POSTGRES = 'VARCHAR'.freeze
    STRING_TYPE_CAST_MYSQL    = 'CHAR'.freeze
    STRING_TYPE_CAST_SQLITE   = 'TEXT'.freeze
    STRING_TYPE_CAST_ORACLE   = 'VARCHAR2(4000)'.freeze

    DB_ADAPTER_STRING_TYPE_CAST = {
      psql: STRING_TYPE_CAST_POSTGRES,
      mysql: STRING_TYPE_CAST_MYSQL,
      mysql2: STRING_TYPE_CAST_MYSQL,
      sqlite: STRING_TYPE_CAST_SQLITE,
      sqlite3: STRING_TYPE_CAST_SQLITE,
      oracle: STRING_TYPE_CAST_ORACLE,
      oracleenhanced: STRING_TYPE_CAST_ORACLE
    }.freeze

    attr_accessor :string_cast

    # rubocop: disable Metrics/AbcSize

    # @return
    #   {
    #     column_key: 'users.name',
    #     column_options: { order: false },
    #     table_class: User,
    #     column_name: :name,
    #     column_type_in_db: :string,
    #   }
    def initialize(cols, global_search_cols)
      # if someone use Array instead of hash, we will use first element
      cols = cols.first if cols.is_a? Array
      @string_cast = _determine_string_type_cast
      @data = cols.each_with_object([]) do |(column_key, column_options), arr|
        raise Error, 'Column options needs to be a Hash' unless column_options.is_a? Hash

        column_options.assert_valid_keys(*COLUMN_OPTIONS)
        table_name, column_name = column_key.to_s.split '.'
        table_class = table_name.singularize.camelcase.constantize
        arr << {
          column_key: column_key,
          column_options: column_options,
          table_class: table_class,
          column_name: column_name,
          column_type_in_db: _determine_db_type_for_column(table_class, column_name),
        }
      end
      @global_search_cols = global_search_cols.each_with_object([]) do |column_key, arr|
        table_name, column_name = column_key.to_s.split '.'
        table_class = table_name.singularize.camelcase.constantize
        arr << {
          column_key: column_key,
          column_options: {},
          table_class: table_class,
          column_name: column_name,
          column_type_in_db: _determine_db_type_for_column(table_class, column_name),
        }
      end
    end
    # rubocop: enable Metrics/AbcSize

    # This is helper
    def _determine_string_type_cast # :nodoc:
      raise NotImplementedError unless defined?(::ActiveRecord::Base)

      DB_ADAPTER_STRING_TYPE_CAST[::ActiveRecord::Base.connection_config[:adapter].to_sym]
    end

    # @return
    #   :string, :integer, :date, :datetime
    def _determine_db_type_for_column(table_class, column_name)
      raise NotImplementedError unless defined?(::ActiveRecord::Base)

      ar_column = table_class.columns_hash[column_name]
      raise Error, "Can't find column #{column_name} in #{table_class.name}" unless ar_column

      ar_column.type
    end

    def searchable
      @data.reject do |column_key_option|
        column_key_option[:column_options][SEARCH_OPTION] == false
      end
    end

    def searchable_and_global_search
      searchable + @global_search_cols
    end

    def [](index)
      raise Error, "You asked for column index=#{index} but there is only #{@data.size} columns" if index >= @data.size

      @data[index]
    end

    def size
      @data.size
    end
  end
end
