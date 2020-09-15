module TrkDatatables
  # rubocop:disable Metrics/ClassLength
  class CalculatedInDb
    def self.human_attribute_name(column_name)
      column_name
    end

    def self.determine_db_type_for_column
      # converts TrkDatatables::IntegerCalculatedInDb to :integer
      name.sub('TrkDatatables::', '').sub('CalculatedInDb', '').downcase.to_sym
    end
  end
  class StringCalculatedInDb < CalculatedInDb; end
  class IntegerCalculatedInDb < CalculatedInDb; end
  class DateCalculatedInDb < CalculatedInDb; end
  class DatetimeCalculatedInDb < CalculatedInDb; end
  class BooleanCalculatedInDb < CalculatedInDb; end

  class ColumnKeyOptions
    include Enumerable

    # All options that you can use for columns:
    #
    # search: if you want to enable global and column search, default is true
    # order: `:asc` or `:desc` or `false`, default is `:desc`
    # @code
    #   def columns
    #     {
    #       'users.name': { search: false }
    #     }
    TITLE_OPTION = :title
    SEARCH_OPTION = :search
    ORDER_OPTION = :order
    SELECT_OPTIONS = :select_options
    PREDEFINED_RANGES = :predefined_ranges
    HIDE_OPTION = :hide
    CLASS_NAME = :class_name
    COLUMN_TYPE_IN_DB = :column_type_in_db
    # this will load date picker
    # SEARCH_OPTION_DATE_VALUE = :date
    # SEARCH_OPTION_DATETIME_VALUE = :datetime
    COLUMN_OPTIONS = [
      SEARCH_OPTION, ORDER_OPTION, TITLE_OPTION, SELECT_OPTIONS,
      PREDEFINED_RANGES, HIDE_OPTION, CLASS_NAME,
      COLUMN_TYPE_IN_DB
    ].freeze

    # for columns that as calculated in db query
    STRING_CALCULATED_IN_DB = :string_calculated_in_db
    INTEGER_CALCULATED_IN_DB = :integer_calculated_in_db
    DATE_CALCULATED_IN_DB = :date_calculated_in_db
    DATETIME_CALCULATED_IN_DB = :datetime_calculated_in_db
    BOOLEAN_CALCULATED_IN_DB = :boolean_calculated_in_db

    # for 'columns' that are calculated in Ruby you need to disable search and
    # order and than it will not be used in queries

    STRING_TYPE_CAST_POSTGRES = 'VARCHAR'.freeze
    STRING_TYPE_CAST_MYSQL    = 'CHAR'.freeze
    STRING_TYPE_CAST_SQLITE   = 'TEXT'.freeze
    STRING_TYPE_CAST_ORACLE   = 'VARCHAR2(4000)'.freeze

    DB_ADAPTER_STRING_TYPE_CAST = {
      postgresql: STRING_TYPE_CAST_POSTGRES,
      mysql: STRING_TYPE_CAST_MYSQL,
      mysql2: STRING_TYPE_CAST_MYSQL,
      sqlite: STRING_TYPE_CAST_SQLITE,
      sqlite3: STRING_TYPE_CAST_SQLITE,
      oracle: STRING_TYPE_CAST_ORACLE,
      oracleenhanced: STRING_TYPE_CAST_ORACLE
    }.freeze

    attr_accessor :string_cast

    # @return
    #   {
    #     column_key: :'users.name',
    #     column_options: { order: false, select_options: User.statuses },
    #     table_class: User,
    #     column_name: :name,
    #     column_type_in_db: :string,
    #     title: 'Name',
    #     html_options: { class: 'my-class' },
    #   }
    def initialize(cols, global_search_cols, predefined_ranges = {})
      @predefined_ranges = predefined_ranges
      # short notation is when we use array of keys.
      # In case first element is hash than we will use that hash
      if cols.is_a? Array
        cols = if cols.first.is_a? Hash
                 cols.first
               else
                 cols.each_with_object({}) do |column_key, hash|
                   hash[column_key.to_sym] = {}
                 end
               end
      end
      _set_data(cols)
      _set_global_search_cols(global_search_cols)
      @string_cast = _determine_string_type_cast
    end

    def _set_data(cols)
      @data = cols.each_with_object([]) do |(column_key, column_options), arr|
        raise Error, 'Column options needs to be a Hash' unless column_options.is_a? Hash

        column_options.assert_valid_keys(*COLUMN_OPTIONS)
        table_name, column_name = column_key.to_s.split '.'
        if table_name.present? && table_name.ends_with?('_calculated_in_db')
          # in calculated columns table_name is used only to determine type
          column_key = column_name
        elsif table_name.present? && column_name.nil?
          raise Error, 'Unless table name ends with _calculated_in_db, column key needs to have one dot for example: posts.name'
        end

        if table_name.blank?
          column_name = column_options[TITLE_OPTION] || 'actions' # some default name for a title
          column_options[SEARCH_OPTION] = false
          column_options[ORDER_OPTION] = false
        else
          table_class = _determine_table_class table_name, column_options[CLASS_NAME]

          unless column_options[SEARCH_OPTION] == false && column_options[ORDER_OPTION] == false
            column_type_in_db = column_options[COLUMN_TYPE_IN_DB] || _determine_db_type_for_column(table_class, column_name)
          end
        end
        arr << {
          column_key: column_key.to_sym,
          column_options: column_options,
          table_class: table_class,
          column_name: column_name,
          column_type_in_db: column_type_in_db,
          # the following are used for RenderHtml
          title: column_options[TITLE_OPTION] || _determine_column_name(table_class, column_name),
          html_options: html_options(column_options, column_type_in_db),
        }
      end
    end

    def _determine_table_class(table_name, class_name = nil)
      # post_users -> PostUser
      # but also check if admin_posts -> Admin::Post so user can defined
      # class_name: 'Admin::Post'
      # https://github.com/duleorlovic/rails/blob/master/activesupport/lib/active_support/inflector/methods.rb#L289
      # note that when class is not eager loaded than const_defined? returns false
      if class_name.present?
        class_name.constantize
      elsif table_name.ends_with? '_calculated_in_db'
        "TrkDatatables::#{table_name.classify}".constantize
      else
        table_name.classify.constantize
      end
    end

    def _set_global_search_cols(global_search_cols)
      raise Error, 'global_search_cols should be array, for example %w[users.name]' unless global_search_cols.is_a? Array

      @global_search_cols = global_search_cols.each_with_object([]) do |column_key, arr|
        table_name, column_name = column_key.to_s.split '.'
        table_class = _determine_table_class table_name
        column_type_in_db = _determine_db_type_for_column(table_class, column_name)
        arr << {
          column_key: column_key.to_sym,
          column_options: {},
          table_class: table_class,
          column_name: column_name,
          column_type_in_db: column_type_in_db,
        }
      end
    end

    # This is helper
    def _determine_string_type_cast # :nodoc:
      if defined?(::ActiveRecord::Base)
        DB_ADAPTER_STRING_TYPE_CAST[::ActiveRecord::Base.connection_config[:adapter].to_sym]
      else
        'not_used'
      end
    end

    # @return
    #   :string, :integer, :date, :datetime
    def _determine_db_type_for_column(table_class, column_name)
      if table_class < TrkDatatables::CalculatedInDb
        table_class.determine_db_type_for_column
      elsif defined?(::ActiveRecord::Base)
        ar_column = table_class.columns_hash[column_name]
        raise Error, "Can't find column #{column_name} in #{table_class.name}" unless ar_column

        ar_column.type
      elsif defined?(::Neo4j::ActiveNode)
        (table_class.declared_properties[column_name][:type] || String).name.downcase
      else
        raise NotImplementedError, 'I work only with ActiveRecord and Neo4j'
      end
    end

    def _determine_column_name(table_class, column_name)
      return column_name.titleize if table_class.blank?

      # maybe we should check if human_attribute_name exists
      table_class.human_attribute_name column_name
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

    def each(&block)
      @data.each(&block)
    end

    def size
      @data.size
    end

    def index_by_column_key(column_key)
      i = @data.find_index do |column_key_option|
        column_key_option[:column_key] == column_key.to_sym
      end
      raise Error, "Can't find index for #{column_key} in #{@data.map { |d| d[:column_key] }.join(', ')}" if i.nil?

      i
    end

    def html_options(column_options, column_type_in_db)
      res = {}
      res['data-searchable'] = false if column_options[SEARCH_OPTION] == false
      res['data-orderable'] = false if column_options[ORDER_OPTION] == false
      res['data-datatable-hidden-column'] = true if column_options[HIDE_OPTION] == true
      res['data-datatable-checkbox'] = true if column_type_in_db == :boolean
      if %i[date datetime].include? column_type_in_db
        res['data-datatable-range'] = column_type_in_db == :datetime ? :datetime : true
        if column_options[PREDEFINED_RANGES].present? ||
           (@predefined_ranges.present? && column_options[PREDEFINED_RANGES] != false)
          res['data-datatable-predefined-ranges'] = if column_options[PREDEFINED_RANGES].is_a? Hash
                                                      column_options[PREDEFINED_RANGES]
                                                    else
                                                      @predefined_ranges
                                                    end
          res['data-datatable-predefined-ranges'].transform_values! do |range|
            [range.first.to_s, range.last.to_s]
          end
        end
      end
      res
    end
  end
  # rubocop:enable Metrics/ClassLength
end
