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

  def trk_dt(method, options)
    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params options
    datatable.send method, datatable.all_items
  end

  def test_order_and_paginate_items
    15.times { |i| Post.create title: "post#{format '%02d', i}" }

    first_post = Post.find_by! title: 'post00'
    last_post = Post.find_by! title: 'post14'
    filtered_items = trk_dt :order_and_paginate_items, order: { 0 => { column: 0, dir: 'desc' } }
    refute_includes filtered_items, first_post
    assert_includes filtered_items, last_post

    filtered_items = trk_dt :order_and_paginate_items, order: { 0 => { column: 0, dir: 'asc' } }
    assert_includes filtered_items, first_post
    refute_includes filtered_items, last_post
  end

  def test_order_items_by_two_columns
    first_user = User.create email: '1@email.com'
    first = Post.create title: '1_post', user: first_user
    second = Post.create title: '2_post', user: first_user
    second_user = User.create email: '2@email.com'
    third = Post.create title: '3_post', user: second_user

    assert_equal_with_message [first, second, third], trk_dt(:order_and_paginate_items, order: { 0 => { column: 0, dir: 'asc' } }), :title

    assert_equal_with_message [third, first, second], trk_dt(:order_and_paginate_items, order: { 0 => { column: 1, dir: 'desc' }, 1 => { column: 0, dir: 'asc' } }), :title
  end

  def test_search_all
    first_user = User.create email: '1@email.com'
    first = Post.create title: '1_post', user: first_user
    second = Post.create title: '2_post', user: first_user
    second_user = User.create email: '2@email.com'
    third = Post.create title: '3_post', user: second_user

    assert_equal_with_message [second], trk_dt(:filter_by_search_all, search: { value: '2_post' }), :title

    assert_equal_with_message [second, third], trk_dt(:filter_by_search_all, search: { value: '2' }), :title

    assert_equal_with_message [first, second, third], trk_dt(:filter_by_search_all, search: { value: '_' }), :title
  end
end
