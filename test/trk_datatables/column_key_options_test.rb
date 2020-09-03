require 'test_helper'

class ColumnKeyOptionTest < Minitest::Test
  def test_nil_column_option
    cols = {
      'posts.title': nil,
    }
    global_search_cols = %w[posts.body]
    e = assert_raises(TrkDatatables::Error) { TrkDatatables::ColumnKeyOptions.new cols, global_search_cols }

    assert_equal 'TrkDatatables: Column options needs to be a Hash', e.message
  end

  def test_wrong_key_column_option
    cols = {
      'posts.title': {wrong: true},
    }
    global_search_cols = []
    e = assert_raises(ArgumentError) { TrkDatatables::ColumnKeyOptions.new cols, global_search_cols }

    assert_match 'Unknown key: :wrong. Valid keys are:', e.message
  end

  class IndexOutOfRangeDatatable < TrkDatatables::ActiveRecord
    def columns
      {
        'posts.title': {},
      }
    end
  end

  def test_index_out_of_range
    datatable = IndexOutOfRangeDatatable.new TrkDatatables::DtParams.sample_view_params order: {'0' => {column: 1}}
    e = assert_raises(TrkDatatables::Error) { datatable.order_items Post.all }

    assert_equal 'TrkDatatables: You asked for column index=1 but there is only 1 columns', e.message
  end

  def test_short_notation
    cols = %i[title body].map { |col| "posts.#{col}" }
    column_key_options = TrkDatatables::ColumnKeyOptions.new cols, []
    assert_equal %i[posts.title posts.body], (column_key_options.searchable.map { |c| c[:column_key] })
  end

  def test_array_notation
    cols = [
      'posts.title': {},
      'posts.body': {search: true},
      'posts.published_on': {search: false},
    ]
    column_key_options = TrkDatatables::ColumnKeyOptions.new cols, []
    assert_equal 2, column_key_options.searchable.size
    assert_equal %i[posts.title posts.body], (column_key_options.searchable.map { |c| c[:column_key] })
  end

  def test_action_column
    cols = {
      'posts.title': {},
      '': {},
    }
    column_key_options = TrkDatatables::ColumnKeyOptions.new cols, []
    assert_equal 1, column_key_options.searchable.size
  end

  def test_html_options
    cols = {
      'posts.user_id': {order: false},
      'posts.title': {search: false},
      'posts.body': {order: true},
      'posts.status': {},
    }
    column_key_options = TrkDatatables::ColumnKeyOptions.new cols, []

    assert_equal({'data-orderable' => false}, column_key_options[0][:html_options])
    assert_equal({'data-searchable' => false}, column_key_options[1][:html_options])
    assert_equal({}, column_key_options[2][:html_options])
    assert_equal({}, column_key_options[3][:html_options])
  end

  def test_default_predefined_ranges
    cols = %i[posts.created_at]
    predefined_ranges = {'Today': Time.now.beginning_of_day..Time.now.end_of_day}
    column_key_options = TrkDatatables::ColumnKeyOptions.new cols, [], predefined_ranges
    expected = {
      'data-datatable-range' => :datetime,
      'data-datatable-predefined-ranges' => {'Today': [predefined_ranges[:Today].first.to_s, predefined_ranges[:Today].last.to_s]}
    }
    assert_equal expected, column_key_options[0][:html_options]
  end

  def test_column_predefined_ranges
    predefined_ranges = {'Today': Time.now.beginning_of_day..Time.now.end_of_day}
    cols = {
      'posts.created_at': {predefined_ranges: predefined_ranges},
      'posts.published_on': {predefined_ranges: false},
    }
    column_key_options = TrkDatatables::ColumnKeyOptions.new cols, []
    expected = {
      'data-datatable-range' => :datetime,
      'data-datatable-predefined-ranges' => {'Today': [predefined_ranges[:Today].first.to_s, predefined_ranges[:Today].last.to_s]}
    }
    assert_equal expected, column_key_options[0][:html_options]
    expected = {
      'data-datatable-range' => true,
    }
    assert_equal expected, column_key_options[1][:html_options]
  end

  def test_determine_table_class_single
    column_key_options = TrkDatatables::ColumnKeyOptions.new [], []
    assert_equal column_key_options._determine_table_class('posts'), Post
  end

  def test_determine_table_class_two_words
    column_key_options = TrkDatatables::ColumnKeyOptions.new [], []
    Object.const_set 'CompanyUser', Class.new
    assert_equal column_key_options._determine_table_class('company_users'), CompanyUser
  end

  def test_determine_table_class_admin_class
    column_key_options = TrkDatatables::ColumnKeyOptions.new [], []
    Object.const_set 'AdminCompany', Class.new
    assert_equal column_key_options._determine_table_class('admin_companies'), AdminCompany
  end

  def test_determine_table_class_admin_module
    column_key_options = TrkDatatables::ColumnKeyOptions.new [], []
    _modul = Object.const_set 'Admin', Module.new
    Object.const_get('Admin')
          .const_set('User', Class.new)
    assert_equal column_key_options._determine_table_class('admin_users', 'Admin::User'), Admin::User
  end

  def test_calculated_in_db
    cols = {
      'string_calculated_in_db.all_messages': {},
      'integer_calculated_in_db.coun_likes': {},
    }
    column_key_options = TrkDatatables::ColumnKeyOptions.new cols, []
    assert_equal TrkDatatables::StringCalculatedInDb, column_key_options[0][:table_class]
    assert_equal :string, column_key_options[0][:column_type_in_db]
    assert_equal :integer, column_key_options[1][:column_type_in_db]
  end
end
