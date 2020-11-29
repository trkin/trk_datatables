module TrkDatatables
  # TODO: extract those to configuration options
  BETWEEN_SEPARATOR = ' - '.freeze
  MULTIPLE_OPTION_SEPARATOR = '|'.freeze
  # maximum page length = 100 (we should not believe params)

  class Error < StandardError
  end

  class Base
    extend TrkDatatables::BaseHelpers

    attr_accessor :column_key_options

    # In tests you can use `spy(:view, default_proc: false)` when you want to initialize without
    # exceptions when view.params is called or @params = ActiveSupport::HashWithIndifferentAccess.new params
    def initialize(view)
      @view = view
      @dt_params = DtParams.new view.params
      @column_key_options = ColumnKeyOptions.new columns, global_search_columns, predefined_ranges
      @preferences = Preferences.new preferences_holder, preferences_field, self.class.name

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
    #       'posts.status' => { search: false },
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

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    # Returns dt_orders or default as array of index and direction
    # https://datatables.net/reference/option/order
    # @return
    #   [
    #     [0, :desc],
    #   ]
    def dt_orders_or_default_index_and_direction
      return @dt_orders_or_default if defined? @dt_orders_or_default

      if columns.blank?
        @dt_orders_or_default = []
      elsif @dt_params.dt_orders.present?
        @dt_orders_or_default = @dt_params.dt_orders
        @preferences.set :order, @dt_params.dt_orders
      else
        check_value = ->(r) { r.is_a?(Array) && r[0].is_a?(Array) && r[0][0].is_a?(Integer) }
        @dt_orders_or_default = @preferences.get(:order, check_value) || default_order
      end
      @dt_orders_or_default
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    def default_order
      [[0, :desc]].freeze
    end

    def default_page_length
      10
    end

    def dt_per_page_or_default
      return @dt_per_page_or_default if defined? @dt_per_page_or_default

      @dt_per_page_or_default = \
        if @dt_params.dt_per_page.present?
          @preferences.set :per_page, @dt_params.dt_per_page
          @dt_params.dt_per_page
        else
          @preferences.get(:per_page) || default_page_length
        end
    end

    # We need this method publicly available since we use it for class method
    # param_set
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
      @dt_params.as_json(
        all_items_count,
        filtered_items_count,
        rows(ordered_paginated_filtered_items),
        additional_data_for_json
      )
    end

    # helper for https://github.com/trkin/trk_datatables/issues/9 which you can
    # override to support group query
    def all_items_count
      all_items.count
    end

    def filtered_items_count
      filtered_items.count
    end

    def additional_data_for_json
      {}
    end

    def filtered_items
      filter_by_search_all filter_by_columns all_items
    end

    def ordered_paginated_filtered_items
      order_and_paginate_items filter_by_search_all filter_by_columns all_items
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

    # Override this to set model where you can store order, index, page length
    # @example
    #   def preferences_holder
    #     @view.current_user
    #   end
    def preferences_holder
      nil
    end

    # Override if you use different than :preferences
    # You can generate with this command:
    # @code
    #   rails g migration add_preferences_to_users preferences:jsonb
    def preferences_field
      :preferences
    end

    def predefined_ranges
      Time.zone ||= 'UTC'
      {
        date: predefined_date_ranges,
        datetime: predefined_datetime_ranges,
      }
    end

    def predefined_date_ranges
      {
        'Today': Time.zone.today..Time.zone.today,
        'Yesterday': [Time.zone.today - 1.day, Time.zone.today - 1.day],
        'This Month': Time.zone.today.beginning_of_month...Time.zone.today,
        'Last Month': Time.zone.today.prev_month.beginning_of_month...Time.zone.today.prev_month.end_of_month,
        'This Year': Time.zone.today.beginning_of_year...Time.zone.today,
      }
    end

    def predefined_datetime_ranges
      {
        'Today': Time.zone.now.beginning_of_day..Time.zone.now.end_of_day,
        'Yesterday': [Time.zone.now.beginning_of_day - 1.day, Time.zone.now.end_of_day - 1.day],
        'This Month': Time.zone.today.beginning_of_month.beginning_of_day...Time.zone.now.end_of_day,
        'Last Month': Time.zone.today.prev_month.beginning_of_month.beginning_of_day...Time.zone.today.prev_month.end_of_month.end_of_day,
        'This Year': Time.zone.today.beginning_of_year.beginning_of_day...Time.zone.today.end_of_day,
      }.transform_values do |range|
        # datepicker expects format 2020-11-29 11:59:59
        range.first.strftime('%F %T')..range.last.strftime('%F %T')
      end
    end
  end
end
