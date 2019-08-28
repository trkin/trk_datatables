module TrkDatatables
  BETWEEN_SEPARATOR = ' - '.freeze
  DEFAULT_ORDER = [{ column_index: 0, direction: :desc }].freeze
  DEFAULT_PAGE_LENGTH = 10

  class Error < StandardError
  end

  class Base
    include TrkDatatables::Preferences
    attr_accessor :column_key_options

    def initialize(view)
      @view = view
      @dt_params = DtParams.new view.params
      @column_key_options = ColumnKeyOptions.new columns, global_search_columns

      # if @dt_params.dt_columns.size != @column_key_options.size
      #   raise Error, "dt_columns size of columns is #{@dt_params.dt_columns.size} \
      #   but column_key_options size is #{@column_key_options.size}"
      # end
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

    # Define columns of a table
    # For simplest version you can notate column_keys as Array of strings
    # @example
    #   def column
    #     %w[posts.id posts.status users.name]
    #   end
    #
    # When you need customisation of some columns, you need to define Hash of column_key => { column_options }
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

    # Define columns that are not returned to page but only used as mathing for
    # global search
    # @example
    #   def global_search_columns
    #     %w[name email].map {|col| "users.#{col}" } + %w[posts.body]
    #   end
    def global_search_columns
      []
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
      raise 'filter_by_columns_is_defined_in_specific_orm' \
        "\n  Extent from TrkDatatables::ActiveRecord instead of TrkDatatables::Base"
    end

    def order_and_paginate_items(_filtered_items)
      raise 'order_and_paginate_items_is_defined_in_specific_orm'
    end

    # Returns dt_orders or default
    # @return
    #   [
    #     { column_index: 0, direction: :desc },
    #   ]
    def dt_orders_or_default
      return @dt_orders_or_default if defined? @dt_orders_or_default

      if @dt_params.dt_orders.present?
        @dt_orders_or_default = @dt_params.dt_orders
        set_preference :order, @dt_params.dt_orders
      else
        @dt_orders_or_default = get_preference(:order) || DEFAULT_ORDER
      end
      @dt_orders_or_default
    end

    def dt_per_page_or_default
      return @dt_per_page_or_default if defined? @dt_per_page_or_default

      @dt_per_page_or_default = \
        if @dt_params.dt_per_page.present?
          set_preference :per_page, @dt_params.dt_per_page
          @dt_params.dt_per_page
        else
          get_preference(:per_page) || DEFAULT_PAGE_LENGTH
        end
    end

    # Set params for columns. This is class method so you do not need datatable
    # instance.
    #
    # @example
    #   link_to 'Published posts for my@email.com',
    #   posts_path(PostsDatatable.params('posts.status': :published,
    #   'users.email: 'my@email.com')
    #
    # You can always use your params for filtering outside of datatable
    # @example
    #   link_to 'Published posts for user1',
    #   posts_path(PostsDatatable.params_set('posts.status': :published).merge(user_id: user1.id))
    def self.params_set(attr)
      datatable = new OpenStruct.new(params: {})
      result = {}
      attr.each do |column_key, value|
        column_index = datatable.index_by_column_key column_key
        result = result.deep_merge DtParams.param_set column_index, value
      end
      result
    end

    # We need this method publicly available since we use it for class method
    # params_set
    def index_by_column_key(column_key)
      @column_key_options.index_by_column_key column_key
    end

    # Helper to populate column search from params, used in
    # RenderHtml#thead
    # @example
    #   @datatable.param_get('users.email')
    def param_get(column_key)
      column_index = index_by_column_key column_key
      @dt_params.param_get column_index
    end

    # _attr is given by Rails template, prefix, layout... not used
    def as_json(_attr = nil)
      # get the value if it is not a relation
      all_count = all_items.count
      filtered_items = filter_by_search_all filter_by_columns all_items
      ordered_paginated_filtered_items = order_and_paginate_items filtered_items
      @dt_params.as_json(
        all_count,
        filtered_items.count,
        rows(ordered_paginated_filtered_items)
      )
    end

    def link_to_rdoc(klass, method)
      "http://localhost:8808/docs/TrkDatatables/#{klass.name}##{method}-instance_method"
    end

    def render_html(search_link = nil, html_options = {})
      if search_link.is_a? Hash
        html_options = search_link
        search_link = nil
      end
      render = RenderHtml.new(search_link, self, html_options)
      render.result
    end
  end
end
