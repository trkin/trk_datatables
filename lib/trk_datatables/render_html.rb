module TrkDatatables
  # rubocop:disable Rails/OutputSafety
  class RenderHtml
    @indent = 0
    def initialize(search_link, datatable, html_options)
      @search_link = search_link
      @datatable = datatable
      @html_options = html_options
      self.class.indent = -1
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

    # rubocop:disable Metrics/AbcSize
    #
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
        html << " #{attribute}='".html_safe << replace_quote(value) << "'".html_safe
      end
      html << if inline
                '>'.html_safe << content.to_s << "</#{tag}>\n".html_safe
              else
                ">\n".html_safe << yield << "\n#{'  ' * self.class.indent}</#{tag}>".html_safe
              end
      self.class.indent -= 1
      html
    end
    # rubocop:enable Metrics/AbcSize

    def _select_tag(options, search_value)
      selected = search_value.to_s.split(MULTIPLE_OPTION_SEPARATOR)
      _content_tag :select, multiple: 'multiple' do
        safe_join(options.map do |key, value|
          _content_tag :option, { value: value }.merge(selected.include?(value.to_s) ? { selected: 'selected' } : {}), key
        end)
      end
    end

    # We need to replace single quote since it is used in option='value'
    def replace_quote(string)
      # do not know those two are different
      #  ERB::Util.html_escape string.to_s.gsub 'aaa', 'bbb'
      #  ERB::Util.html_escape string.to_s
      # since it is safebuffer and html_safe, this will output with single
      # quotes for example: data-datatable-multiselect='      <select multiple='multi
      # ERB::Util.html_escape string
      # replace single quote with double quote
      string.to_s.tr "'", '"'
    end

    def table_tag_server
      _content_tag(
        :table,
        class: "table table-bordered table-striped #{@html_options[:class]}",
        'data-datatable': true,
        'data-datatable-ajax-url': @search_link,
        'data-datatable-page-length': @datatable.dt_per_page_or_default,
        'data-datatable-order': @datatable.dt_orders_or_default_index_and_direction.to_json,
        # for initial page load we do not have ability to show recordsTotal
        # https://github.com/trkin/trk_datatables_js/issues/1
        'data-datatable-total-length': @datatable.filtered_items.count,
      ) do
        thead << "\n".html_safe << tbody
      end
    end

    def thead
      _content_tag :thead do
        _content_tag :tr do
          safe_join(@datatable.column_key_options.map do |column_key_option|
            options = column_key_option[:html_options]
            search_value = @datatable.param_get(column_key_option[:column_key]) if options['data-searchable'] != false
            options['data-datatable-search-value'] = search_value if search_value.present?
            select_options = column_key_option[:column_options][ColumnKeyOptions::SELECT_OPTIONS]
            options['data-datatable-multiselect'] = _select_tag select_options, search_value if select_options.present?
            _content_tag :th, options, column_key_option[:title]
          end)
        end
      end
    end

    def tbody
      # use raw html_safe only for <td>, not for data since it could be injection
      # hole if we show, for example some params
      _content_tag :tbody do
        safe_join(@datatable.rows(@datatable.ordered_paginated_filtered_items).map do |row|
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
  # rubocop:enable Rails/OutputSafety
end
