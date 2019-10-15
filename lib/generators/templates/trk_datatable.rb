class <%= class_name.pluralize %>Datatable < TrkDatatables::ActiveRecord
  def columns
    {
<% class_name.constantize.columns.each do |column| -%>
<% next if %w[created_at updated_at].include? column.name -%>
      '<%= table_name %>.<%= column.name %>': {},
<% end -%>
    }
  end

  def all_items
    <%= class_name %>.all
  end

  def rows(filtered)
    filtered.map do |<%= singular_table_name %>|
      [
<% class_name.constantize.columns.each do |column| -%>
<% next if %w[created_at updated_at].include? column.name -%>
<% if column.name == 'id' -%>
        @view.link_to(<%= singular_table_name %>.id, <%= singular_table_name %>),
<% else -%>
        <%= singular_table_name %>.<%= column.name %>,
<% end -%>
<% end -%>
      ]
    end
  end
end
