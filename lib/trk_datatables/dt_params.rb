module TrkDatatables
  # This class wraps databases format https://datatables.net/manual/server-side#Returned-data
  #
  # In future we can use some another datatables like
  # https://github.com/gregnb/mui-datatables
  # https://github.com/handsontable/handsontable
  # https://github.com/cloudflarearchive/backgrid (archived)
  class DtParams
    DEFAULT_PAGE_LENGTH = 10
    DEFAULT_SORT_DIR = :desc
    DEFAULT_SORT_COL = 0

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

    # This is typecast so we can safelly use order[:column]
    # @return array of { column_index: 0, direction: :asc }
    def orders
      @params[:order].each_with_object([]) do |(_index, order), a|
        # here we ignore index and assume all columns are present in params
        a << {
          column_index: order[:column].to_i,
          direction: order[:dir]&.casecmp('ASC')&.zero? ? :asc : :desc,
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

    def self.sample_params(options = {})
      HashWithIndifferentAccess.new(
        'draw' => '1',
        'start' => '0',
        'length' => '10',
        'search' => {
          'value' => '', 'regex' => 'false'
        },
        'order' => {
          '0' => { 'column' => '0', 'dir' => 'desc' }
        },
        'columns' => {
          '0' => {
            'data' => 'username', 'name' => '', 'searchable' => 'true', 'orderable' => 'true',
            'search' => {
              'value' => '', 'regex' => 'false'
            }
          },
          '1' => {
            'data' => 'email', 'name' => '', 'searchable' => 'true', 'orderable' => 'true',
            'search' => {
              'value' => '', 'regex' => 'false'
            }
          },
          '2' => {
            'data' => 'first_name', 'name' => '', 'searchable' => 'true', 'orderable' => 'false',
            'search' => {
              'value' => '', 'regex' => 'false'
            }
          },
        },
      ).merge options
    end
  end
end
