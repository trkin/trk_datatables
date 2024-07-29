RSpec.describe <%= @trk_class_name %> do
  it "properly renders datatable" do
    get <%= class_name.downcase.pluralize %>_path
    expect(response).to be_ok
  end

  it "search and ordering" do
    mock_view = OpenStruct.new(params: {})
    datatable = <%= @trk_class_name %>.new(mock_view)

    datatable.columns.each_with_index do |_, idx|
      post search_<%= class_name.downcase.pluralize %>_path, params: {
        search: {value: "some_value"},
        order: {"0": {column: idx, dir: "asc"}}
      }
      expect(response).to be_ok
    end
  end
end

