require 'test_helper'

class TrkDatatablesActiveRecordTest < Minitest::Test
  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'users.email': {},
      }
    end

    def rows(filtered)
      filtered.map do |post|
        [
          post.title,
          post.user&.email,
        ]
      end
    end
  end

  def test_order_and_paginate_items
    15.times { |i| Post.create title: "post#{format '%02d', i}" }

    first_post = Post.find_by! title: 'post00'
    last_post = Post.find_by! title: 'post14'
    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params order: { 0 => { column: 0, dir: 'desc' } }
    filtered_items = datatable.order_and_paginate_items datatable.all_items
    refute_includes filtered_items, first_post
    assert_includes filtered_items, last_post

    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params order: { 0 => { column: 0, dir: 'asc' } }
    filtered_items = datatable.order_and_paginate_items datatable.all_items
    assert_includes filtered_items, first_post
    refute_includes filtered_items, last_post
  end

  def test_order_items_by_two_columns
    first_user = User.create email: '1@email.com'
    first = Post.create title: '1_post', user: first_user
    second = Post.create title: '2_post', user: first_user
    second_user = User.create email: '2@email.com'
    third = Post.create title: '3_post', user: second_user

    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params order: { 0 => { column: 0, dir: 'asc' } }
    filtered_items = datatable.order_and_paginate_items datatable.all_items
    expected = [first, second, third]
    assert_equal_with_message expected, filtered_items, :title

    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params order: { 0 => { column: 1, dir: 'asc' }, 1 => { column: 0, dir: 'desc' } }
    filtered_items = datatable.order_and_paginate_items datatable.all_items
    expected = [second, first, third]
    assert_equal_with_message expected, filtered_items, :title
  end
end
