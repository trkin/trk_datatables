require 'test_helper'

class DtParamsTest < Minitest::Test
  def test_empty_params
    dt_params = TrkDatatables::DtParams.new({})
    assert_equal [], dt_params.dt_columns
  end

  def test_raise_exception_if_additional_is_not_hash
    dt_params = TrkDatatables::DtParams.new({})
    assert_raises ArgumentError do
      dt_params.as_json 0, 0, [], 0
    end
  end
end
