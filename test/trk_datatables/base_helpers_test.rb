require 'test_helper'

class TrkDatatablesBaseHelpersTest < Minitest::Test
  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.published_date': {},
        'posts.status': {select_options: Post.statuses},
        'users.email': {},
      }
    end

    def rows(_filtered)
      []
    end
  end

  def test_param_set
    actual = PostsDatatable
             .param_set('users.email', 'my@email.com')
             .deep_merge(PostsDatatable.param_set('posts.published_date', Date.parse('2019-10-20')..Date.parse('2019-10-22')))
             .deep_merge(PostsDatatable.param_set('posts.status', Post.statuses.values_at(:published, :promoted)))
             .deep_merge(user_id: 1)
    expected = {
      columns: {
        '1' => {
          search: {
            value: '2019-10-20 - 2019-10-22',
          }
        },
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

  def test_range_string
    act = PostsDatatable.range_string(1..5)
    exp = "1 #{TrkDatatables::BETWEEN_SEPARATOR} 5"
    assert_equal exp, act
  end

  def test_form_field_name
    act = PostsDatatable.form_field_name 'users.email'
    exp = 'columns[3][search][value]'
    assert_equal exp, act
  end
end
