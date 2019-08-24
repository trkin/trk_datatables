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
    COLUMN_OPTIONS = %i[search order].freeze

    TYPE_CAST_POSTGRES = 'VARCHAR'.freeze
    TYPE_CAST_MYSQL    = 'CHAR'.freeze
    TYPE_CAST_SQLITE   = 'TEXT'.freeze
    TYPE_CAST_ORACLE   = 'VARCHAR2(4000)'.freeze

    DB_ADAPTER_TYPE_CAST = {
      psql: TYPE_CAST_POSTGRES,
      mysql: TYPE_CAST_MYSQL,
      mysql2: TYPE_CAST_MYSQL,
      sqlite: TYPE_CAST_SQLITE,
      sqlite3: TYPE_CAST_SQLITE,
      oracle: TYPE_CAST_ORACLE,
      oracleenhanced: TYPE_CAST_ORACLE
    }.freeze

    attr_accessor :global_search_type_cast

    # @return
    #   {
    #     column_key: 'users.name',
    #     column_options: { order: false },
    #     table_class: User,
    #     column_name: :name,
    #     global_search_type_cast: 'TEXT',
    #   }
    def initialize(cols)
      # if someone use Array instead of hash, we will use first element
      cols = cols.first if cols.is_a? Array
      @global_search_type_cast = _determine_string_type_cast
      @data = cols.each_with_object([]) do |(column_key, column_options), arr|
        raise TrkDatatables::Error, 'Column options needs to be a Hash' unless column_options.is_a? Hash

        column_options.assert_valid_keys(*COLUMN_OPTIONS)
        table_name, column_name = column_key.to_s.split '.'
        table_class = table_name.singularize.camelcase.constantize
        arr << {
          column_key: column_key,
          column_options: column_options,
          table_class: table_class,
          column_name: column_name,
          global_search_type_cast: global_search_type_cast,
        }
      end
    end

    def _determine_string_type_cast
      if defined?(ActiveRecord::Base)
        DB_ADAPTER_TYPE_CAST[ActiveRecord::Base.connection_config[:adapter]]

      else
        TYPE_CAST_POSTGRES
      end
    end

    def searchable
      @data.reject do |column_key_option|
        column_key_option[:column_options][:search] == false
      end
    end

    def [](index)
      raise TrkDatatables::Error, "You asked for column index=#{index} but there is only #{@data.size} columns" if index >= @data.size

      @data[index]
    end
  end
end
