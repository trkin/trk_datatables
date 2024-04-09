require "test_helper"

class TrkDatatablesActiveRecordWithCalculatedColumnsTest < Minitest::Test
  class PostsWithCommentsCountDatatable < TrkDatatables::ActiveRecord
    def columns
      {
        "posts.id": {},
        "string_calculated_in_db.title_and_body": {},
        "integer_calculated_in_db.comments_count": {}
      }
    end

    def all_items
      Post.select(%(
                  posts.*,
                  #{title_and_body} AS title_and_body,
                  (#{comments_count}) AS comments_count
                  ))
    end

    def title_and_body
      "posts.title || ' ' || posts.body"
    end

    def comments_count
      <<~SQL
        (SELECT COUNT(*) FROM comments
        WHERE comments.post_id = posts.id)
      SQL
    end

    def default_order
      [[2, :desc]]
    end
  end

  def dt_send(method, options = {})
    datatable = PostsWithCommentsCountDatatable.new TrkDatatables::DtParams.sample_view_params options
    datatable.send method, datatable.all_items
  end

  def test_order_and_paginate_items
    15.times do |i|
      post = Post.create title: "post#{format "%<i>02d", i: i}"
      i.times do
        Comment.create post: post
      end
    end

    first_post = Post.find_by! title: "post00"
    last_post = Post.find_by! title: "post14"
    # default is comments_count
    filtered = dt_send :order_and_paginate_items
    refute_includes filtered, first_post
    assert_includes filtered, last_post

    filtered = dt_send :order_and_paginate_items, order: {0 => {column: 2, dir: "asc"}}
    assert_includes filtered, first_post
    refute_includes filtered, last_post

    assert_equal_with_message [last_post],
      dt_send(:filter_by_columns, columns: {"2": {searchable: true, search: {value: "14"}}}), :title
  end
end
