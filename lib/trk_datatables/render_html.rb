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
      tag = tag.to_s
      html = "#{'  ' * self.class.indent}<#{tag}"
      options.each do |attribute, value|
        html << " #{attribute}='#{value}'"
      end
      html << if inline
                ">#{content}</#{tag}>\n"
              else
                ">\n#{yield}\n#{'  ' * self.class.indent}</#{tag}>"
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
        'data-datatable-order': @datatable.dt_orders_or_default.to_json,
        'data-datatable-total-length': @datatable.all_items.count
      ) do
        thead + "\n" + tbody
      end
    end

    def thead
      _content_tag 'thead' do
        _content_tag :tr do
          @datatable.column_key_options.map do |column_key_option|
            options = column_key_option[:html_options]
            column_search_value = @datatable.param_get(column_key_option[:column_key])
            options['data-datatable-search-value'] = column_search_value if column_search_value.present?
            _content_tag :th, options, column_key_option[:title]
          end.join
        end
      end
    end

    def tbody
      # use raw html_safe only for <td>, not for data since it could be injection
      # hole if we show, for example some params
      ordered_paginated_filtered_items = @datatable.order_and_paginate_items \
        @datatable.filter_by_search_all @datatable.filter_by_columns @datatable.all_items
      _content_tag :tbody do
        @datatable.rows(ordered_paginated_filtered_items).map do |row|
          _content_tag :tr do
            row.map do |col|
              _content_tag :td, col
            end.join
          end
        end.join("\n")
      end
    end

    def table_tag_client
      ''
    end
  end
end
