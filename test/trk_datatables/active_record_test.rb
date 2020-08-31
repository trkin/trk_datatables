require 'test_helper'

class TrkDatatablesActiveRecordTest < Minitest::Test
  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.published_on': {},
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

  def posts_dt(method, options = {})
    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params options
    datatable.send method, datatable.all_items
  end

  def test_order_and_paginate_items
    15.times { |i| Post.create title: "post#{format '%02d', i}" }

    first_post = Post.find_by! title: 'post00'
    last_post = Post.find_by! title: 'post14'
    filtered = posts_dt :order_and_paginate_items, order: {0 => {column: 0, dir: 'desc'}}
    refute_includes filtered, first_post
    assert_includes filtered, last_post

    filtered = posts_dt :order_and_paginate_items, order: {0 => {column: 0, dir: 'asc'}}
    assert_includes filtered, first_post
    refute_includes filtered, last_post
  end

  def test_order_items_by_two_columns
    first_user = User.create email: '1@email.com'
    first = Post.create title: '1_post', user: first_user
    second = Post.create title: '2_post', user: first_user
    second_user = User.create email: '2@email.com'
    third = Post.create title: '3_post', user: second_user

    assert_equal_with_message [first, second, third], posts_dt(:order_and_paginate_items, order: {0 => {column: 0, dir: 'asc'}}), :title

    assert_equal_with_message [third, first, second], posts_dt(:order_and_paginate_items, order: {0 => {column: 3, dir: 'desc'}, 1 => {column: 0, dir: 'asc'}}), :title
  end

  def test_filter_by_search_all
    first_user = User.create email: '1@email.com'
    first = Post.create title: '1_post', user: first_user, published_on: '2020-01-01'
    second = Post.create title: '2_post', user: first_user, published_on: '2021-01-01'
    second_user = User.create email: '2@email.com'
    third = Post.create title: '3_post', user: second_user, published_on: '2022-01-01'

    assert_equal_with_message [second], posts_dt(:filter_by_search_all, search: {value: '2_post'}), :title
    assert_equal_with_message [first, second, third], posts_dt(:filter_by_search_all, search: {value: '2'}), :title
    assert_equal_with_message [third], posts_dt(:filter_by_search_all, search: {value: '2022-01-01'}), :title
    assert_equal_with_message [first, second, third], posts_dt(:filter_by_search_all, search: {value: '_'}), :title
  end

  def test_filter_by_columns_one_string_one_column
    user1 = User.create email: '1@email.com'
    post1a = Post.create title: '1a_post', user: user1, published_on: '2020-01-01'
    post1b = Post.create title: '1b_post', user: user1, published_on: '2021-01-01'
    user2 = User.create email: '2@email.com'
    post2 = Post.create title: '2_post', user: user2, published_on: '2021-01-01'

    assert_equal_with_message [post1a], posts_dt(:filter_by_columns, columns: {'0': {searchable: true, search: {value: '1a_post'}}}), :title
    assert_equal_with_message [post1b, post2], posts_dt(:filter_by_columns, columns: {'1': {searchable: true, search: {value: '2021-01-01'}}}), :title
  end

  def test_filter_by_columns_two_strings_two_columns
    user1 = User.create email: '1@email.com'
    post1a = Post.create title: '1a_post', user: user1, published_on: '2020-01-01'
    post1b = Post.create title: '1b_post', user: user1, published_on: '2021-03-01'
    user2 = User.create email: '2@email.com'
    post2a = Post.create title: '2a_post', user: user2, published_on: '2022-03-01'
    post2b = Post.create title: '2b_post', user: user2, published_on: '2023-03-01'

    assert_equal_with_message [post1a, post2a], posts_dt(:filter_by_columns, columns: {'0': {searchable: true, search: {value: 'a_post post'}}}), :title
    assert_equal_with_message [post1b, post2a, post2b], posts_dt(:filter_by_columns, columns: {'0': {}, '1': {searchable: true, search: {value: '20 03'}}}), :title
    # intersection of two previous queries
    assert_equal_with_message [post2a], posts_dt(:filter_by_columns, columns: {'0': {searchable: true, search: {value: 'a_post post'}}, '1': {searchable: true, search: {value: '20 03'}}}), :title
  end

  def test_filter_column_between_integer_and_float
    user1 = User.create email: '1@email.com', latitude: '1.1'
    post1a = Post.create title: '1a_post', user: user1, status: 0
    post1b = Post.create title: '1b_post', user: user1, status: 1
    user2 = User.create email: '2@email.com', latitude: '1.2'
    post2a = Post.create title: '2a_post', user: user2, status: 2
    post2b = Post.create title: '2b_post', user: user2, status: 3

    # integer
    assert_equal_with_message [post1b, post2a], posts_dt(:filter_by_columns, columns: {'2': {searchable: true, search: {value: "1#{TrkDatatables::BETWEEN_SEPARATOR}2"}}}), :title
    assert_equal_with_message [post1a, post1b, post2a], posts_dt(:filter_by_columns, columns: {'2': {searchable: true, search: {value: " #{TrkDatatables::BETWEEN_SEPARATOR}2"}}}), :title
    assert_equal_with_message [post2a, post2b], posts_dt(:filter_by_columns, columns: {'2': {searchable: true, search: {value: "2#{TrkDatatables::BETWEEN_SEPARATOR}"}}}), :title
    assert_equal_with_message [post1a, post1b, post2a, post2b], posts_dt(:filter_by_columns, columns: {'2': {searchable: true, search: {value: " #{TrkDatatables::BETWEEN_SEPARATOR}  "}}}), :title

    # float
    assert_equal_with_message [post2a, post2b], posts_dt(:filter_by_columns, columns: {'4': {searchable: true, search: {value: "1.15#{TrkDatatables::BETWEEN_SEPARATOR}1.2"}}}), :title

    # integer and float without separator
    assert_equal_with_message [post1a, post1b], posts_dt(:filter_by_columns, columns: {'2': {searchable: true, search: {value: "#{TrkDatatables::BETWEEN_SEPARATOR}1"}}, '4': {searchable: true, search: {value: '.1'}}}), :title

    # invalid format
    assert_equal_with_message Post.all.to_a, posts_dt(:filter_by_columns, columns: {'2': {searchable: true, search: {value: " #{TrkDatatables::BETWEEN_SEPARATOR}a2"}}}), :title
  end

  # since in test we use UTC in db, we need to Time.zone.parse (Time.parse will use your current
  # timezone but in db it is UTC). In params you can add timezone info (+0100)
  def test_filter_column_between_date_and_datetime
    Time.use_zone('Belgrade') do
      user1 = User.create email: '1@email.com', registered_at: Time.zone.parse('2010-01-01 07:00:00')
      post1a = Post.create title: '1a_post', user: user1, published_on: '2020-01-01'
      post1b = Post.create title: '1b_post', user: user1, published_on: '2020-02-01'
      user2 = User.create email: '2@email.com', registered_at: Time.zone.parse('2015-01-01 07:00:00')
      post2a = Post.create title: '2a_post', user: user2, published_on: '2020-03-01'
      post2b = Post.create title: '2b_post', user: user2, published_on: '2020-04-01'

      # date
      assert_equal_with_message [post1b, post2a], posts_dt(:filter_by_columns, columns: {'1': {searchable: true, search: {value: "2020-01-15#{TrkDatatables::BETWEEN_SEPARATOR}2020-03-02"}}}), :published_on
      assert_equal_with_message [post2a, post2b], posts_dt(:filter_by_columns, columns: {'1': {searchable: true, search: {value: "2020-03-01#{TrkDatatables::BETWEEN_SEPARATOR}"}}}), :published_on

      # datetime
      assert_equal [post1a, post1b], posts_dt(:filter_by_columns, columns: {'5': {searchable: true, search: {value: "2010-01-01 07:00:00#{TrkDatatables::BETWEEN_SEPARATOR}2010-01-01 07:00:00"}}}), "it should match #{post1a.user.registered_at} #{post1b.user.registered_at}"
      # in CEST timezone offset if 1h
      # assert_equal_with_message [post1a, post1b], posts_dt(:filter_by_columns, columns: { '5': { searchable: true, search: { value: "2010-01-01 06:00:00 +0000#{TrkDatatables::BETWEEN_SEPARATOR}2010-01-01 06:00:00 +0000" } } }), :published_on

      # both date and datetime
      assert_equal_with_message [post1b], posts_dt(:filter_by_columns, columns: {'1': {searchable: true, search: {value: "2020-02-01#{TrkDatatables::BETWEEN_SEPARATOR}"}}, '5': {searchable: true, search: {value: "#{TrkDatatables::BETWEEN_SEPARATOR}2010-01-01 07:00:00"}}}), :title
    end
  end

  def test_invalid_date
    post1a = Post.create title: '1a_post', published_on: '2020-01-01'
    assert_equal_with_message [post1a], posts_dt(:filter_by_columns, columns: {'1': {searchable: true, search: {value: "2020-01-45#{TrkDatatables::BETWEEN_SEPARATOR}2020-03-02"}}}), :published_on
    assert_equal_with_message [post1a], posts_dt(:filter_by_columns, columns: {'1': {searchable: true, search: {value: "#{TrkDatatables::BETWEEN_SEPARATOR} "}}}), :published_on
    assert_equal_with_message [post1a], posts_dt(:filter_by_columns, columns: {'1': {searchable: true, search: {value: "-#{TrkDatatables::BETWEEN_SEPARATOR} "}}}), :published_on
  end

  def test_global_search
    user1 = User.create email: '1@email.com', name: 'user1_name'
    post1a = Post.create title: '1a_post', user: user1, body: '1a_body'
    post1b = Post.create title: '1b_post', user: user1, body: '1b_body'
    user2 = User.create email: '2@email.com', name: 'user2_name'
    _post2 = Post.create title: '2a_post', user: user2, body: '2a_body'

    assert_equal_with_message [post1b], posts_dt(:filter_by_search_all, search: {value: '1b_body'}), :title
    assert_equal_with_message [post1a, post1b], posts_dt(:filter_by_search_all, search: {value: '_body user1_name'}), :title
  end

  class MultiselectsDatatable < TrkDatatables::ActiveRecord
    def columns
      {
        'posts.status': {select_options: Post.statuses},
      }
    end
  end
  def test_select_options
    _post1 = Post.create status: :draft
    post2 = Post.create status: :published
    post3 = Post.create status: :promoted
    _post4 = Post.create status: :landing

    datatable = MultiselectsDatatable.new TrkDatatables::DtParams.sample_view_params columns: {'0': {searchable: true, search: {value: 'published|promoted'}}}
    assert_equal_with_message [post2, post3], datatable.filter_by_columns(Post.all), :status
  end

  def test_parse_from_to_dates
    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params
    from = '2000-01-01'
    to = '2000-01-02'
    column_key_option = {column_type_in_db: :date}
    assert_equal ['2000-01-01 00:00:00', '2000-01-02 23:59:59'], (datatable._parse_from_to(from, to, column_key_option).map { |t| t.strftime '%Y-%m-%d %H:%M:%S' })
  end

  def test_parse_from_to_date_with_am
    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params
    from = '2000-01-01'
    to = '2000-01-02 22:22:22 PM'
    column_key_option = {column_type_in_db: :date}
    assert_equal ['2000-01-01 00:00:00', '2000-01-02 22:22:22'], (datatable._parse_from_to(from, to, column_key_option).map { |t| t.strftime '%Y-%m-%d %H:%M:%S' })
  end
end
