module TrkDatatables
  class Error < StandardError
  end

  class Base
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

    def initialize(view)
      @view = view
      @dt_params = DtParams.new view.params
      @type_cast = if defined?(ActiveRecord::Base)
                     DB_ADAPTER_TYPE_CAST[ActiveRecord::Base.connection_config[:adapter]]

                   else
                     TYPE_CAST_POSTGRES
                   end
    end

    # Get all items from db
    #
    # @example
    #   def all_items
    #     Post.joins(:users).published
    #   end
    # @return [ActiveRecord::Relation]
    def all_items
      raise NotImplementedError, "You should implement #{__method__} method"
    end

    # Define columns of a table, column_key => { column_options }
    #
    # @example
    #   def columns
    #     {
    #       'posts.id': {},
    #       'posts.status' => { multiselect: true },
    #       'users.name' => { order: false },
    #     }
    #   end
    # @return Array of Hash
    def columns
      raise NotImplementedError, "You should implement #{__method__} method #{link_to_rdoc self.class, __method__}"
    end

    def _get_column_key_and_column_options_by_index(index)
      # https://stackoverflow.com/a/7040927/287166
      cols = columns
      # if someone use Array instead of hash, we will use first element
      cols = columns.first if columns.is_a? Array
      cols.to_a[index]
    end

    def searchable_columns
      columns.reject do |_column_key, column_options|
        column_options[:search]
      end
    end

    # Define page data
    # @example
    #   def rows(page_items)
    #     page_items.map do |post|
    #     post_status = @view.content_tag :span, post.status, class: "label label-#{@view.convert_status_to_class post.status}"
    #       [
    #         post.id,
    #         post_status,
    #         @view.link_to(post.user.name, post.user)
    #       ]
    #     end
    #   end
    def rows(_page_items)
      raise NotImplementedError, "You should implement #{__method__} method"
    end

    def filter_by_search_all(_all)
      raise 'filter_by_columns_is_defined_in_specific_orm'
    end

    def filter_by_columns(_all)
      raise 'filter_by_columns_is_defined_in_specific_orm'
    end

    def order_and_paginate_items(_filtered_items)
      raise 'order_and_paginate_items_is_defined_in_specific_orm'
    end

    def as_json
      # get the value if it is not a relation
      all_count = all_items.count
      filtered_items = filter_by_search_all filter_by_columns all_items
      ordered_paginated_filtered_items = order_and_paginate_items filtered_items
      {
        draw: @view.params[:draw].to_i,
        recordsTotal: all_count,
        recordsFiltered: filtered_items.count,
        data: rows(ordered_paginated_filtered_items),
      }
    end

    def link_to_rdoc(klass, method)
      "http://localhost:8808/docs/TrkDatatables/#{klass.name}##{method}-instance_method"
    end
  end
end
