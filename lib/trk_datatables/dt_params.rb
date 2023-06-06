module TrkDatatables
  # rubocop:disable Metrics/ClassLength

  # This class wraps databases format https://datatables.net/manual/server-side#Returned-data
  #
  # In future we can use some another datatables like
  # https://github.com/gregnb/mui-datatables
  # https://github.com/handsontable/handsontable
  # https://github.com/cloudflarearchive/backgrid (archived)
  class DtParams
    def initialize(params)
      params.permit! if params.respond_to? :permit!
      @params = ActiveSupport::HashWithIndifferentAccess.new params
    end

    def dt_offset
      @params[:start].to_i
    end

    def dt_per_page
      return if @params[:length].blank?

      @params[:length].to_i
    end

    # def page
    #   (dt_offset / dt_per_page) + 1
    # end

    # Typecast so we can safelly use dt_order[0] (Integer) and
    # dt_order[1] (:asc/:desc)
    # @return
    #   [
    #     [ 2, :asc ],
    #     [ 1, :desc ],
    #   ]
    def dt_orders
      return @dt_orders if defined? @dt_orders

      @dt_orders = []
      return @dt_orders if @params[:order].blank?

      @dt_orders = \
        @params[:order].each_with_object([]) do |(_index, dt_order), a|
          # for order we ignore key (_index) since order is preserved
          a << [
            dt_order[:column].to_i,
            dt_order[:dir]&.to_s&.casecmp('ASC')&.zero? ? :asc : :desc,
          ]
        end
      @dt_orders
    end

    # Typecast so we can safelly use dt_column[:searchable] (Boolean),
    # dt_column[:orderable] (Boolean), dt_column[:search_value] (String)
    #
    # Returned size could be different from columns size, we match key from params to
    # insert in appropriate place, and all other values are default
    # @return
    #   [
    #     { index: 0, searchable: true, orderable: true, search_value: 'dule' },
    #   ]
    def dt_columns
      return @dt_columns if defined? @dt_columns

      @dt_columns = []
      return @dt_columns unless @params[:columns].respond_to? :each

      @params[:columns].each.map do |(dt_position, dt_column)|
        @dt_columns[dt_position.to_i] = {
          index: dt_position.to_i,
          searchable: dt_column[:searchable].to_s != 'false', # if nil as it is in set_params, than use true
          orderable: dt_column[:orderable].to_s != 'false', # if nil as it is in set_params, than use true
          search_value: (dt_column[:search] && dt_column[:search][:value]) || '',
        }
      end
      @dt_columns.each_with_index do |dt_column, i|
        next unless dt_column.nil?

        @dt_columns[i] = {
          index: i,
          searchable: true,
          orderable: true,
          search_value: '',
        }
      end
    end

    def search_all
      @params.dig(:search, :value) || ''
    rescue TypeError => e
      raise Error, e.message + '. Global search is in a format: { "search": { "value": "ABC" } }'
    end

    def as_json(all_count, filtered_count, data, additional = {})
      additional = {} if additional.nil?
      raise Error, 'additional_data_for_json needs to be a hash' unless additional.is_a? Hash

      draw = @params[:draw].to_i
      {
        draw: draw,
        recordsTotal: all_count,
        recordsFiltered: filtered_count,
        **additional,
        data: data,
      }
    end

    def self.param_set(column_index, value)
      {columns: {column_index.to_s => {search: {value: value}}}}
    end

    def self.order_set(column_index, direction)
      {order: {'0': {column: column_index, dir: direction}}}
    end

    def self.form_field_name(column_index)
      "columns[#{column_index}][search][value]"
    end

    def param_get(column_index)
      @params.dig :columns, column_index.to_s, :search, :value
    rescue TypeError => e
      raise Error, "#{e.message}. Column search is in a format: { \"columns\": { \"0\": { \"search\": { \"value\": { \"ABC\" } } } } }"
    end

    def self.sample_view_params(options = {})
      OpenStruct.new(
        params: sample_params(options),
      )
    end

    def self.sample_params(options = {})
      HashWithIndifferentAccess.new(
        draw: '1',
        start: '0',
        length: '10',
        search: {
          value: '', regex: 'false'
        },
        order: {
          '0': {column: '0', dir: 'desc'}
        },
        # [:columns] should have the same size as column_key_options since we
        # ignore keys, and use positions
        columns: {
          '0': {
            searchable: 'true',
            orderable: 'true',
            search: {
              value: '', regex: 'false'
            }
          },
          '1': {
            searchable: 'true',
            orderable: 'true',
            search: {
              value: '', regex: 'false'
            }
          },
          '2': {
            searchable: 'true',
            orderable: 'false',
            search: {
              value: '', regex: 'false'
            }
          },
        },
      ).merge options
    end
  end
  # rubocop:enable Metrics/ClassLength
end
