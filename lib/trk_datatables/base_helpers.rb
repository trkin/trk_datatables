module TrkDatatables
  module BaseHelpers
    # Set params for column search. This is class method so you do not need
    # datatable instance.
    #
    # @example
    #   link_to 'Published posts for my@email.com',
    #   posts_path(PostsDatatable.params('posts.status': :published,
    #   'users.email: 'my@email.com')
    #
    # You can always use your params for filtering outside of datatable and
    # merge to params
    # @example
    #   link_to 'Published posts for user1',
    #   posts_path(PostsDatatable.param_set('posts.status', :published).merge(user_id: user1.id))
    def param_set(column_key, value, view = nil)
      datatable = new view || OpenStruct.new(params: {})
      value = value.join MULTIPLE_OPTION_SEPARATOR if value.is_a? Array
      value = [value.first, value.last].join BETWEEN_SEPARATOR if value.is_a? Range
      column_index = datatable.index_by_column_key column_key
      DtParams.param_set column_index, value
    end

    # Set sort for column. This is class method so you do not need
    # datatable instance.
    #
    # @example
    #   link_to 'Sort by email',
    #   posts_path(PostsDatatable.order_set('users.email', :desc)
    def order_set(column_key, direction = :asc, view = nil)
      datatable = new view || OpenStruct.new(params: {})
      column_index = datatable.index_by_column_key column_key
      DtParams.order_set column_index, direction
    end

    # Get the form field name for column. This is class method so you do not
    # need datatable instance. It returns something like
    # 'column[3][search][value]`. For global search you can use
    # '[search][value]`
    #
    # @example
    # form_tag url: posts_path, method: :get do |f|
    #   f.text_field PostsDatatable.form_field_name('users.email'), 'my@email.com'
    #   # it is the same as
    #   f.text_field 'columns[3][search][value]', 'my@email.com'
    def form_field_name(column_key)
      datatable = new OpenStruct.new(params: {})
      column_index = datatable.index_by_column_key column_key
      DtParams.form_field_name column_index
    end

    # For range you can this helper to insert BETWEEN_SEPARATOR
    def range_string(range)
      raise Error, "#{range} is not a Range" unless range.is_a? Range

      from = range.min
      to = range.max
      "#{from} #{BETWEEN_SEPARATOR} #{to}"
    end
  end
end
