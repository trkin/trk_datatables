# Trk Datatables

This is a source for [trk_datatables gem](https://rubygems.org/gems/trk_datatables) that you
can use with [trk_datatables npm package](https://www.npmjs.com/package/trk_datatables) for easier usage of [Datatables plug-in for jQuery library](https://datatables.net)

After [configuration](https://github.com/trkin/trk_datatables#configuration) you can use
one line commands (like `@datatable.render_html`) to generate first page in html
(so non-js crawlers can see it), global search, filtering and sorting, adding
map and other complex listing based on GET params.

## Table of Contents
<!--ts-->
   * [Trk Datatables](#trk-datatables)
      * [Table of Contents](#table-of-contents)
      * [Installation](#installation)
      * [Usage example in Ruby on Rails](#usage-example-in-ruby-on-rails)
      * [Configuration](#configuration)
         * [Global search](#global-search)
         * [Column 'ILIKE' and 'BETWEEN' search](#column-ilike-and-between-search)
         * [Column 'IN' search](#column-in-search)
         * [Action column](#action-column)
         * [Params](#params)
         * [Saved Preferences (optional)](#saved-preferences-optional)
         * [Additional data to json response](#additional-data-to-json-response)
      * [Different response for mobile app](#different-response-for-mobile-app)
      * [Debug](#debug)
      * [Alternatives](#alternatives)
      * [Development](#development)
      * [Contributing](#contributing)
      * [License](#license)
      * [Code of Conduct](#code-of-conduct)

<!-- Added by: orlovic, at: Mon Sep  9 09:38:44 CEST 2019 -->

<!--te-->

## Installation

Add this line to your application's Gemfile:

```ruby
# Gemfile
gem 'trk_datatables'
```

You need to create a class that inherits from `TrkDatatables::ActiveRecord` (you
can use Rails generator)

```
```

## Usage example in Ruby on Rails

For a table you need to define `columns` and `rows` (well that is obvious 😌).
In datatable class you also need to define `all_items` method which will  be
used to populate `rows` with paginated, sorted and filtered items (we will call
them `filtered`)

```
# app/datatables/posts_datatable.rb
class PostsDatatable < TrkDatatables::ActiveRecord
  def columns
    {
      'posts.title': {},
      'users.email': {},
    }
  end

  def rows(filtered)
    filtered.map do |post|
      [
        @view.link_to(post.title, post),
        post.user&.email,
      ]
    end
  end

  def all_items
    Post.left_joins(:user)
  end
end
```

In controller you need to initialize with `view_context`

```
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new view_context
  end

  def search
    render json: PostsDatatable.new(view_context)
  end
end
```

In controller add a route to `:search`

```
# config/routes.rb
Rails.application.routes.draw do
  resources :posts do
    colletion do
      post :search
    end
  end
end
```

And finally in a view, use `render_html` to have first page show up prerendered

```
# app/views/posts/index.html
<h1>Posts</h1>
<%= @datatable.render_html search_posts_path(format: :json) %>
```

## Configuration

Datatables will search all columns that you defined as keys in `columns` using a
`ILIKE` (ie `.matches` in Arel ActiveRecord).

In datatables there are two types of search: global (search all columns) and
column search (search is done for specific columns).

### Global search

You can add more columns to global search by overriding `global_search_columns`
method.

```
class PostsDatatable < TrkDatatables::ActiveRecord
  def global_search_columns
    # in addition to columns those fields will be used to match global search
    %w[posts.body users.name]
  end
end
```

### Column 'ILIKE' search

All columns are by default casted to string and `ILIKE` is perfomed.

If you do not need any specific column configuration,
for example custom `title`, than instead of defining columns as key/value
pairs, you can define them in one line as array of column_key.

```
# app/datatables/posts_datatable.rb
class PostsDatatable < TrkDatatables::ActiveRecord
  def columns
    # instead of
    # {
    #   id: {},
    #   title: {},
    #   body: {},
    # }.each_with_object({}) { |(key, value), obj| obj["posts.#{key}"] = value }
    # you can use one liner
    # %w[posts.id posts.title posts.body]
    # or even shorter using map
    %i[id title body].map { |col| "posts.#{col}" }
  end
end
```
### Column 'BETWEEN' search

For column search when search string contains BETWEEN_SEPARATOR (` - `) and
column_type_in_db as one of the: `:date`, `:datetime`, `:integer` and
`:float` than `BETWEEN` is perfomed.

For columns `:date` there will be `data-datatable-range='true'`
attribute so [data range picker](http://www.daterangepicker.com/) will be
automatically loaded. For `:datetime` you can enable time picker in addition to
date.

```
# app/datatables/posts_datatable.rb
class PostsDatatable < TrkDatatables::ActiveRecord
  def columns
    {
      'posts.created_at': { time_picker: true },
    }
  end
end
```

To enable shortcuts for selecting ranges, you can override predefined ranges and
enable for all `date` and `datetime` column

```
# app/datatables/base_trk_datatable.rb
class BaseTrkDatable < TrkDatatables::ActiveRecord
  def predefined_ranges
    # defaults are defined in https://github.com/trkin/trk_datatables/blob/master/lib/trk_datatables/base.rb
    default_predefined_ranges
  end
end
```
or you can enable for all `date` and `datetime columns` for specific datatable
by defining `predefined_ranges` on that datatable. You can disable for specific columns also
```
class PostsDatatable < TrkDatatables::ActiveRecord
  def predefined_ranges
    {
      'Today': Time.zone.now.beginning_of_day..Time.zone.now.end_of_day,
      'Yesterday': [Time.zone.now.beginning_of_day - 1.day, Time.zone.now.end_of_day - 1.day],
      'This Month': Time.zone.today.beginning_of_month...Time.zone.now.end_of_day,
      'Last Month': Time.zone.today.prev_month.beginning_of_month...Time.zone.today.prev_month.end_of_month.end_of_day,
      'This Year': Time.zone.today.beginning_of_year...Time.zone.today.end_of_day,
    }
  end

  def columns
    {
      'posts.created_at': {}, # this column will have predefined_ranges
      'posts.published_date': { predefined_ranges: false }
  end
end
```
or you can define for specific column
```
# app/datatables/posts_datatable.rb
class PostsDatatable < TrkDatatables::ActiveRecord
  def columns
    {
      'posts.created_at': { predefined_ranges: { 'Today': Time.zone.now.beginning_of_day...Time.zone.now.end_of_day } },
    }
  end
end
```

We use
[ActiveSupport::TimeZone](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html)
so if you use different than UTC you need to set `Time.zone =` in your app [example values](https://github.com/rails/rails/blob/master/activesupport/lib/active_support/values/time_zone.rb#L31). Whenever Time.parse is used (and we use `Time.zone.parse` for params) it needs correct zone (in Rails you can set timezone in `config.time_zone` or use [browser timezone rails gem](https://github.com/kbaum/browser-timezone-rails)).

### Column 'IN' search

You can use column_option `select_options: [['name1', 'value1']]` so select box
will be loaded and match if `col IN (value1|value2)`.

```
def columns
  {
    'posts.title': {},
    'posts.status': { select_options: Post.statuses },
  }
end

# in view
link_to 'Active', search_posts_path(PostsDatatable.param_set('posts.status':
Post.statues.values_at(:published, :promoted)))
```

You can use column_option `search: :checkbox` so for column_type_in_db `:boolean`
it will provide checkbox. For other column_type_in_db it will match if value is
NULL or NOT NULL.

### Action column

You can use one column for actions (so it is not related to any db column) just
use empty column_key

```
  def columns
    {
      'posts.title': {},
      '': { title: "<a href='#'>Check all</a>" },
    }
  end

  def rows(filtered)
    filtered.each do |post|
      actions = @view.link_to('View', post)
      [
        post.title,
        actions,
      ]
    end
  end
```

### Default order and page length

You can override default order (index and direction) and default page length so
if user did not request some order or page length (and if it is not found in
save preferences) and this default values will be used

```
# app/datatables/posts_datatable.rb
class PostsDatatable
  # when we show some invoice_no on first column, and that is reset every year
  # on first april, thatn it is better is to use date column ordering
  def default_order
    [[3, :desc]]
  end

  def default_page_length
    20
  end
end
```

### Params

To set parameters that you can use for links to set column search value, use
this `PostsDatatable.param_set` for example

```
link_to 'Posts for my@email.com and my_title', \
  posts_path(
    PostsDatatable.param_set('users.email', 'my@email.com')
      .deep_merge(PostsDatatable.param_set('posts.title', 'my_title')
      .deep_merge(user_id: 1)
  )
```

This will generate
```
```

If you need, you can fetch params with this helper

```
PostsDatatable.param_get('users.email', params)
```

### Saved Preferences (optional)

You can save column order and page length in User.preferences field so
next time user navigate to same page will see the same order and page length. It
can be `string` or `text`, or some advance `hstore` or `jsonb`.

```
rails g migration add_preferences_to_users preferences:string

# app/models/user.rb
class User
  # no need to serialize if it is hstore or jsonb
  serialize :preferences, Hash
end

# app/datatables/posts_datatable.rb
class PostsDatatable
  def preferences_holder
    @view.current_user
  end

  def preferences_field
    # this is default so do not need to define unless you use different field
    :preferences
  end
end
```

It will store order and page lenght inside `dt_preferences` on
`user.preferences`.

### Additional data to json response

You can override `additional_data_for_json` that will be included in json
response
```
# app/datatables/posts_datatable.rb
class PostsDatatable < TrkDatatables::ActiveRecord
  def additional_data_for_json
    { columns: columns }
  end
end
```

## Different response for mobile app

You can use condition to provide different data, for example let's assume
`@view.api_user?` returns true for json requests from mobile app. Here is
example that provides different columns for normal and api_user:

```
# app/datatables/posts_datatable.rb
class PostsDatatable < TrkDatatables::ActiveRecord
  def columns
    @view.api_user? ? columns_for_api : columns_for_html
  end

  def columns_for_html
    {
      'subscribers.subscriberid': {},
      'subscribers.name': {},
    }
  end

  def columns_for_api
    {
      'subscribers.id': {},
      'subscribers.subscriberid': {},
      'subscribers.name': {},
    }
  end

  def rows(filtered)
    @view.api_user? ? rows_for_api(filtered) : rows_for_html(filtered)
  end

  def rows_for_html(filtered)
    filtered.map do |subscriber|
      [
        @view.link_to(subscriber.subscriberid, subscriber),
        subscriber.name,
      ]
    end
  end

  def rows_for_api(filtered)
    filtered.map do |subscriber|
      [
        subscriber.id,
        subscriber.subscriberid,
        subscriber.name,
      ]
    end
  end

  def additional_data_for_json
    @view.api_user? ? columns_for_api : nil
  end
end
```

## Debug

You can override some of the methos and put byebug, for example
```
# app/datatables/posts_datatable.rb
class PostsDatatable < TrkDatatables::ActiveRecord
  def as_json(_ = nil)
    byebug
    super
  end
end

```

## Alternatives

There are alternatives, for example:
* [jbox-web/ajax-datatables-rails](https://github.com/jbox-web/ajax-datatables-rails)
excellent gem but it's scope is only to produce JSON. I wanted to have server
side rendering and more advance listing

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Instead of installing you can point directly to your path
```
# Gemfile
# for index, ordering, pagination and searching
# gem 'trk_datatables', '~>0.1'
# no need to `bundle update trk_datatables` when switch to local
gem 'trk_datatables', path: '~/gems/trk_datatables'
```

To generate docs you can run

```
yard server

# clear cache
rm -rf .yardoc/
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trkin/trk_datatables. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TrkDatatables project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/trkin/trk_datatables/blob/master/CODE_OF_CONDUCT.md).
