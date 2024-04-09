class <%= @trk_class_name %> < TrkDatatables::ActiveRecord
  def columns
    {
<% @skip_model || class_name.constantize.columns.each do |column| -%>
<% next if %w[created_at updated_at].include? column.name -%>
      "<%= table_name %>.<%= column.name %>": {},
<% end -%>
    }
  end

  def all_items
    # you can use @view.params
    <%= class_name %>.all
  end

  def rows(filtered)
    # you can use @view.link_to and other helpers
    filtered.map do |<%= singular_table_name %>|
      [
<% @skip_model || class_name.constantize.columns.each do |column| -%>
<% next if %w[created_at updated_at].include? column.name -%>
<% if column.name == "id" -%>
        @view.link_to(<%= singular_table_name %>.id, <%= singular_table_name %>),
<% else -%>
        <%= singular_table_name %>.<%= column.name %>,
<% end -%>
<% end -%>
      ]
    end
  end
end
