require 'test_helper'

class DtParamsTest < Minitest::Test
  def test_empty_params
    dt_params = TrkDatatables::DtParams.new({})
    assert_equal [], dt_params.dt_columns
  end

  def test_raise_exception_if_additional_is_not_hash
    dt_params = TrkDatatables::DtParams.new({})
    e = assert_raises TrkDatatables::Error do
      dt_params.as_json 0, 0, [], 0
    end

    assert_equal 'TrkDatatables: additional_data_for_json needs to be a hash', e.message
  end

  def test_raise_exception_if_global_search_is_not_correct_format
    dt_params = TrkDatatables::DtParams.new(search: 'AAA')
    e = assert_raises TrkDatatables::Error do
      dt_params.search_all
    end

    assert_equal 'TrkDatatables: String does not have #dig method. Global search is in a format: { "search": { "value": "ABC" } }', e.message
  end

  def test_raise_exception_if_column_search_is_not_correct_format
    # this will not raise error
    dt_params = TrkDatatables::DtParams.new(columns: { '0': { search: { value: 'AAA' } } })
    dt_params.param_get 0
    # or when there is a nil
    dt_params = TrkDatatables::DtParams.new(columns: {})
    dt_params.param_get 0
    # but wrong format will raise error
    dt_params = TrkDatatables::DtParams.new(columns: { '0': { search: 'AAA' } })
    e = assert_raises TrkDatatables::Error do
      dt_params.param_get 0
    end

    assert_equal 'TrkDatatables: String does not have #dig method. Column search is in a format: { "columns": { "0": { "search": { "value": { "ABC" } } } } }', e.message
  end
end
