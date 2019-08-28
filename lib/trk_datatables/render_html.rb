module TrkDatatables
  class RenderHtml
    @indent = 0
    def initialize(search_link, datatable, html_options)
      @search_link = search_link
      @datatable = datatable
      @html_options = html_options
      self.class.indent = 0
    end

    def result
      if @search_link.nil?
        table_tag_client
      else
        table_tag_server
      end
    end

    class << self
      attr_accessor :indent
    end

    # https://github.com/rails/rails/blob/master/actionview/lib/action_view/helpers/output_safety_helper.rb#L33
    def safe_join(array, sep = $,)
      sep = ERB::Util.unwrapped_html_escape(sep)

      array.map { |i| ERB::Util.unwrapped_html_escape(i) }.join(sep).html_safe
    end

    # _content_tag :p, 'Hi'
    # _content_tag :p, class: 'button', 'Hi'
    # _content_tag :div, do
    # _content_tag :div, class: 'background' do
    def _content_tag(tag, options = {}, content = nil)
      if !options.is_a?(Hash)
        inline = true
        content = options
        options = {}
      elsif content.present?
        inline = true
      end
      self.class.indent += 1
      html = "#{'  ' * self.class.indent}<#{tag}".html_safe
      options.each do |attribute, value|
        html << " #{attribute}='".html_safe << value.to_s << "'".html_safe
      end
      html << if inline
                '>'.html_safe << content.to_s << "</#{tag}>\n".html_safe
              else
                ">\n".html_safe << yield << "\n#{'  ' * self.class.indent}</#{tag}>".html_safe
              end
      self.class.indent -= 1
      html
    end

    def table_tag_server
      _content_tag(
        :table,
        class: "table table-bordered table-striped #{@html_options[:class]}",
        'data-datatable': true,
        'data-datatable-ajax-url': @search_link,
        'data-datatable-page-length': @datatable.dt_per_page_or_default,
        'data-datatable-order': @datatable.dt_orders_or_default.map {|dt_order| [dt_order[:column_index], dt_order[:direction].to_s.html_safe]}.to_json, # TODO: legacy
        'data-datatable-total-length': @datatable.all_items.count
      ) do
        thead << "\n".html_safe << tbody
      end
    end

    def thead
      _content_tag 'thead' do
        _content_tag :tr do
          safe_join(@datatable.column_key_options.map do |column_key_option|
            options = column_key_option[:html_options]
            search_value = @datatable.param_get(column_key_option[:column_key]) if options['data-searchable'] != false
            options['data-datatable-search-value'] = search_value if search_value.present?
            _content_tag :th, options, column_key_option[:title]
          end)
        end
      end
    end

    def tbody
      # use raw html_safe only for <td>, not for data since it could be injection
      # hole if we show, for example some params
      ordered_paginated_filtered_items = @datatable.order_and_paginate_items \
        @datatable.filter_by_search_all @datatable.filter_by_columns @datatable.all_items
      _content_tag :tbody do
        safe_join(@datatable.rows(ordered_paginated_filtered_items).map do |row|
          _content_tag :tr do
            safe_join(row.map do |col|
              _content_tag :td, col
            end)
          end
        end, "\n".html_safe)
      end
    end

    def table_tag_client
      ''
    end
  end
end
