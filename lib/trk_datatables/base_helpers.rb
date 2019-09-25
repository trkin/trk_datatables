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
    def param_set(column_key, value)
      datatable = new OpenStruct.new(params: {})
      value = value.join MULTIPLE_OPTION_SEPARATOR if value.is_a? Array
      column_index = datatable.index_by_column_key column_key
      DtParams.param_set column_index, value
    end

    # Get the form field name for column. This is class method so you do not
    # need datatable instance.
    #
    # @example
    # form_tag url: posts_path, method: :get do |f|
    #   f.text_field PostsDatatable.form_field_name('users.email'), 'my@email.com'
    def form_field_name(column_key)
      datatable = new OpenStruct.new(params: {})
      column_index = datatable.index_by_column_key column_key
      DtParams.form_field_name column_index
    end

    # For range you can this helper to insert BETWEEN_SEPARATOR
    def range_string(range)
      raise ArgumentError, "#{range} is not a Range" unless range.is_a? Range

      from = range.min
      to = range.max
      "#{from} #{BETWEEN_SEPARATOR} #{to}"
    end
  end
end
