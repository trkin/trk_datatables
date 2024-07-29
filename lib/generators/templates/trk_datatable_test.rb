require "test_helper"

class <%= @trk_class_name %>Test < ActionDispatch::IntegrationTest
  test "properly renders datatable" do
    get <%= class_name.downcase.pluralize %>_path
    assert_response :success
  end

  test "search and ordering" do
    mock_view = OpenStruct.new(params: {})
    datatable = <%= @trk_class_name %>.new(mock_view)

    datatable.columns.each_with_index do |_, idx|
      post search_<%= class_name.downcase.pluralize %>_path, params: {
        search: {value: "some_value"},
        order: {"0": {column: idx, dir: "asc"}}
      }
      assert_response :success

      expect(response).to be_ok
    end
  end
end
