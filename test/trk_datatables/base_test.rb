require 'test_helper'

class TrkDatatablesBaseTest < Minitest::Test
  def view
    OpenStruct.new(
      params: {}
    )
  end

  class NotCompletedDatatable < TrkDatatables::Base; end

  class BlankDatatable < TrkDatatables::Base
    def columns
      {}
    end

    def rows(_)
      []
    end

    def all_items
      []
    end
  end

  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.published_date': {},
        'posts.status': { select_options: Post.statuses },
        'users.email': {},
      }
    end

    def rows(filtered)
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

  def test_param_set
    actual = PostsDatatable.param_set('users.email', 'my@email.com')
      .deep_merge(PostsDatatable.param_set('posts.status', Post.statuses.values_at(:published, :promoted)))
      .deep_merge(user_id: 1)
    expected = {
      columns: {
        '2' => {
          search: {
            value: '1|2'
          }
        },
        '3' => {
          search: {
            value: 'my@email.com'
          }
        }
      },
      user_id: 1,
    }
    assert_equal expected, actual

    e = assert_raises(TrkDatatables::Error) { PostsDatatable.param_set('non_existing.table', 'my@email.com') }
    assert_match "Can't find index for non_existing.table in posts.title", e.message
  end

  def test_param_get
    params = {
      columns: {
        '0' => {
          search: {
            value: 'my_title'
          }
        },
        '3' => {
          search: {
            value: 'my@email.com'
          }
        }
      }
    }
    datatable = PostsDatatable.new OpenStruct.new params: params
    actual = datatable.param_get('users.email')
    assert_equal 'my@email.com', actual

    e = assert_raises(TrkDatatables::Error) { datatable.param_get('non_existing.table') }
    assert_match "Can't find index for non_existing.table in posts.title", e.message
  end

  def test_additional_data
    blank = PostsDatatable.new(view)
    act = blank.as_json
    exp = {
      draw: 0,
      recordsTotal: 0,
      recordsFiltered: 0,
      columns: PostsDatatable.new(view).columns,
      data: [],
    }
    assert_equal exp, act
  end
end
