require 'test_helper'

class TrkDatatablesActiveRecordTest < Minitest::Test
  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.published_date': {},
        'posts.status': {},
        'users.email': {},
        'users.latitude': {},
        'users.registered_at': {},
      }
    end

    def global_search_columns
      %w[users.name posts.body]
    end

    def rows(_filtered); end
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

    assert_equal_with_message [third, first, second], trk_dt(:order_and_paginate_items, order: { 0 => { column: 3, dir: 'desc' }, 1 => { column: 0, dir: 'asc' } }), :title
  end

  def test_filter_by_search_all
    first_user = User.create email: '1@email.com'
    first = Post.create title: '1_post', user: first_user, published_date: '2020-01-01'
    second = Post.create title: '2_post', user: first_user, published_date: '2021-01-01'
    second_user = User.create email: '2@email.com'
    third = Post.create title: '3_post', user: second_user, published_date: '2022-01-01'

    assert_equal_with_message [second], trk_dt(:filter_by_search_all, search: { value: '2_post' }), :title
    assert_equal_with_message [first, second, third], trk_dt(:filter_by_search_all, search: { value: '2' }), :title
    assert_equal_with_message [third], trk_dt(:filter_by_search_all, search: { value: '2022-01-01' }), :title
    assert_equal_with_message [first, second, third], trk_dt(:filter_by_search_all, search: { value: '_' }), :title
  end

  def test_filter_by_columns_one_string_one_column
    user1 = User.create email: '1@email.com'
    post1a = Post.create title: '1a_post', user: user1, published_date: '2020-01-01'
    post1b = Post.create title: '1b_post', user: user1, published_date: '2021-01-01'
    user2 = User.create email: '2@email.com'
    post2 = Post.create title: '2_post', user: user2, published_date: '2021-01-01'

    assert_equal_with_message [post1a], trk_dt(:filter_by_columns, columns: { '0': { searchable: true, search: { value: '1a_post' } } }), :title
    assert_equal_with_message [post1b, post2], trk_dt(:filter_by_columns, columns: { '1': { searchable: true, search: { value: '2021-01-01' } } }), :title
  end

  def test_filter_by_columns_two_strings_two_columns
    user1 = User.create email: '1@email.com'
    post1a = Post.create title: '1a_post', user: user1, published_date: '2020-01-01'
    post1b = Post.create title: '1b_post', user: user1, published_date: '2021-03-01'
    user2 = User.create email: '2@email.com'
    post2a = Post.create title: '2a_post', user: user2, published_date: '2022-03-01'
    post2b = Post.create title: '2b_post', user: user2, published_date: '2023-03-01'

    assert_equal_with_message [post1a, post2a], trk_dt(:filter_by_columns, columns: { '0': { searchable: true, search: { value: 'a_post post' } } }), :title
    assert_equal_with_message [post1b, post2a, post2b], trk_dt(:filter_by_columns, columns: { '0': {}, '1': { searchable: true, search: { value: '20 03' } } }), :title
    # intersection of two previous queries
    assert_equal_with_message [post2a], trk_dt(:filter_by_columns, columns: { '0': { searchable: true, search: { value: 'a_post post' } }, '1': { searchable: true, search: { value: '20 03' } } }), :title
  end

  def test_filter_column_between_integer_and_float
    user1 = User.create email: '1@email.com', latitude: '1.1'
    post1a = Post.create title: '1a_post', user: user1, status: 0
    post1b = Post.create title: '1b_post', user: user1, status: 1
    user2 = User.create email: '2@email.com', latitude: '1.2'
    post2a = Post.create title: '2a_post', user: user2, status: 2
    post2b = Post.create title: '2b_post', user: user2, status: 3

    # integer
    assert_equal_with_message [post1b, post2a], trk_dt(:filter_by_columns, columns: { '2': { searchable: true, search: { value: "1#{TrkDatatables::BETWEEN_SEPARATOR}2" } } }), :title
    assert_equal_with_message [post1a, post1b, post2a], trk_dt(:filter_by_columns, columns: { '2': { searchable: true, search: { value: " #{TrkDatatables::BETWEEN_SEPARATOR}2" } } }), :title
    assert_equal_with_message [post2a, post2b], trk_dt(:filter_by_columns, columns: { '2': { searchable: true, search: { value: "2#{TrkDatatables::BETWEEN_SEPARATOR}" } } }), :title
    assert_equal_with_message [post1a, post1b, post2a, post2b], trk_dt(:filter_by_columns, columns: { '2': { searchable: true, search: { value: " #{TrkDatatables::BETWEEN_SEPARATOR}  " } } }), :title

    # float
    assert_equal_with_message [post2a, post2b], trk_dt(:filter_by_columns, columns: { '4': { searchable: true, search: { value: "1.15#{TrkDatatables::BETWEEN_SEPARATOR}1.2" } } }), :title

    # integer and float without separator
    assert_equal_with_message [post1a, post1b], trk_dt(:filter_by_columns, columns: { '2': { searchable: true, search: { value: "#{TrkDatatables::BETWEEN_SEPARATOR}1" } }, '4': { searchable: true, search: { value: '.1' } } }), :title
  end

  # rubocop:disable Rails/TimeZone
  # since in test we use UTC in db, we need to Time.parse so it is your current
  # timezone. In params you can add timezone info (+0100)
  def test_filter_column_between_date_and_datetime
    user1 = User.create email: '1@email.com', registered_at: Time.parse('2010-01-01 07:00:00')
    post1a = Post.create title: '1a_post', user: user1, published_date: '2020-01-01'
    post1b = Post.create title: '1b_post', user: user1, published_date: '2020-02-01'
    user2 = User.create email: '2@email.com', registered_at: Time.parse('2015-01-01 07:00:00')
    post2a = Post.create title: '2a_post', user: user2, published_date: '2020-03-01'
    post2b = Post.create title: '2b_post', user: user2, published_date: '2020-04-01'

    # date
    assert_equal_with_message [post1b, post2a], trk_dt(:filter_by_columns, columns: { '1': { searchable: true, search: { value: "2020-01-15#{TrkDatatables::BETWEEN_SEPARATOR}2020-03-02" } } }), :published_date
    assert_equal_with_message [post2a, post2b], trk_dt(:filter_by_columns, columns: { '1': { searchable: true, search: { value: "2020-03-01#{TrkDatatables::BETWEEN_SEPARATOR}" } } }), :published_date

    # datetime
    assert_equal_with_message [post1a, post1b], trk_dt(:filter_by_columns, columns: { '5': { searchable: true, search: { value: "2010-01-01 07:00:00#{TrkDatatables::BETWEEN_SEPARATOR}2010-01-01 07:00:00" } } }), :published_date
    # in CEST timezone offset if 1h
    # assert_equal_with_message [post1a, post1b], trk_dt(:filter_by_columns, columns: { '5': { searchable: true, search: { value: "2010-01-01 06:00:00 +0000#{TrkDatatables::BETWEEN_SEPARATOR}2010-01-01 06:00:00 +0000" } } }), :published_date

    # both date and datetime
    assert_equal_with_message [post1b], trk_dt(:filter_by_columns, columns: { '1': { searchable: true, search: { value: "2020-02-01#{TrkDatatables::BETWEEN_SEPARATOR}" } }, '5': { searchable: true, search: { value: "#{TrkDatatables::BETWEEN_SEPARATOR}2010-01-01 07:00:00" } } }), :title
  end
  # rubocop:enable Rails/TimeZone

  def test_global_search
    user1 = User.create email: '1@email.com', name: 'user1_name'
    post1a = Post.create title: '1a_post', user: user1, body: '1a_body'
    post1b = Post.create title: '1b_post', user: user1, body: '1b_body'
    user2 = User.create email: '2@email.com', name: 'user2_name'
    _post2 = Post.create title: '2a_post', user: user2, body: '2a_body'

    assert_equal_with_message [post1b], trk_dt(:filter_by_search_all, search: { value: '1b_body' }), :title
    assert_equal_with_message [post1a, post1b], trk_dt(:filter_by_search_all, search: { value: '_body user1_name' }), :title
  end
end
