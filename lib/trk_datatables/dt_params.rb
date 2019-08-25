module TrkDatatables
  # This class wraps databases format https://datatables.net/manual/server-side#Returned-data
  #
  # In future we can use some another datatables like
  # https://github.com/gregnb/mui-datatables
  # https://github.com/handsontable/handsontable
  # https://github.com/cloudflarearchive/backgrid (archived)
  class DtParams
    DEFAULT_PAGE_LENGTH = 10
    DEFAULT_ORDER_DIR = :desc
    BETWEEN_SEPARATOR = ' - '.freeze

    def initialize(params)
      @params = ActiveSupport::HashWithIndifferentAccess.new params
      # we can store somewhere per_page and order params
    end

    def offset
      @params[:start].to_i
    end

    def per_page
      if @params[:length].present?
        @params[:length].to_i
      else
        DEFAULT_PAGE_LENGTH
      end
    end

    def page
      (offset / per_page) + 1
    end

    # Typecast so we can safelly use dt_order[:column_index] (Integer) and
    # dt_order[:direction] (:asc/:desc)
    # @return array of { column_index: 2, direction: :asc }
    def dt_orders
      @dt_orders ||= \
        @params[:order].each_with_object([]) do |(_index, dt_order), a|
          # here we ignore index
          a << {
            column_index: dt_order[:column].to_i,
            direction: dt_order[:dir]&.casecmp('ASC')&.zero? ? :asc : :desc,
          }
        end
    end

    # Typecast so we can safelly use dt_column[:searchable] (Boolean),
    # dt_column[:orderable] (Boolean), dt_column[:search_value] (String)
    #
    # We assume that the size is the same as columns size
    # @return
    #   [
    #     { index: 0, searchable: true, orderable: true, search_value: 'dule' },
    #   ]
    def dt_columns
      @dt_columns ||= \
        @params[:columns].each_with_index.map do |(_, dt_column), index| # ignore index
          {
            index: index,
            searchable: dt_column[:searchable] == true,
            orderable: dt_column[:orderable] == true,
            search_value: (dt_column[:search] && dt_column[:search][:value]) || '',
          }
        end
    end

    def search_all
      @params.dig(:search, :value) || ''
    end

    def self.sample_view_params(options = {})
      OpenStruct.new(
        params: sample_params(options),
      )
    end

    # [:columns] should have the same size as column_key_options
    def self.sample_params(options = {})
      HashWithIndifferentAccess.new(
        draw: '1',
        start: '0',
        length: '10',
        search: {
          value: '', regex: 'false'
        },
        order: {
          '0': { column: '0', dir: 'desc' }
        },
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
end
