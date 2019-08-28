require 'test_helper'

class DtParamsTest < Minitest::Test
  def test_empty_params
    dt_params = TrkDatatables::DtParams.new({})
    assert_equal [], dt_params.dt_columns
  end
end
