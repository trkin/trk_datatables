require 'test_helper'

class TrkDatatablesBaseTest < Minitest::Test
  def view
    OpenStruct.new(
      params: {}
    )
  end

  class NotCompletedDatatable < TrkDatatables::Base; end

  class BlankDatatable < TrkDatatables::ActiveRecord
    def columns
      {}
    end

    def rows(_)
      []
    end

    def all_items
      Post.all
    end
  end

  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.published_on': {},
        'posts.status': {select_options: Post.statuses},
        'users.email': {},
      }
    end

    def rows(_filtered)
      []
    end

    def additional_data_for_json
      {
        columns: columns,
      }
    end
  end

  def test_all_items_not_defined
    assert_raises(NotImplementedError) { NotCompletedDatatable.new(view).all_items }
  end

  def test_columns_not_defined
    assert_raises(NotImplementedError) { NotCompletedDatatable.new(view).columns }
  end

  def test_rows_not_defined
    assert_raises(NotImplementedError) { NotCompletedDatatable.new(view).rows nil }
  end

  def test_as_json
    blank = BlankDatatable.new(view)
    blank.stub :filter_by_search_all, [] do
      blank.stub :filter_by_columns, [] do
        blank.stub :order_and_paginate_items, [] do
          act = blank.as_json
          exp = {
            draw: 0,
            recordsTotal: 0,
            recordsFiltered: 0,
            data: [],
          }
          assert_equal exp, act
        end
      end
    end
  end

  def test_additional_data
    datatable = PostsDatatable.new(view)
    act = datatable.as_json
    exp = {
      draw: 0,
      recordsTotal: 0,
      recordsFiltered: 0,
      columns: PostsDatatable.new(view).columns,
      data: [],
    }
    assert_equal exp, act
  end

  def test_dt_orders_or_default_index_and_direction
  end
end
