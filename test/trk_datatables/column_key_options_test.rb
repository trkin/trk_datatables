require 'test_helper'

class ColumnKeyOptionTest < Minitest::Test
  def test_nil_column_option
    cols = {
      'posts.title': nil,
    }
    e = assert_raises(TrkDatatables::Error) { TrkDatatables::ColumnKeyOptions.new cols }

    assert_equal 'Column options needs to be a Hash', e.message
  end

  def test_wrong_key_column_option
    cols = {
      'posts.title': { wrong: true },
    }
    e = assert_raises(ArgumentError) { TrkDatatables::ColumnKeyOptions.new cols }

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
    datatable = IndexOutOfRangeDatatable.new TrkDatatables::DtParams.sample_view_params order: { '0' => { column: 1 } }
    e = assert_raises(TrkDatatables::Error) { datatable.order_items Post.all }

    assert_equal 'You asked for column index=1 but there is only 1 columns', e.message
  end

  def test_searchable
    cols = {
      'posts.title': {},
      'posts.body': { search: true },
      'posts.published_at': { search: false },
    }
    column_key_options = TrkDatatables::ColumnKeyOptions.new cols
    assert_equal 2, column_key_options.searchable.size
    assert_equal %i[posts.title posts.body], (column_key_options.searchable.map { |c| c[:column_key] })
  end
end
