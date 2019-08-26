# Trk Datatables

This is a [trk_datatables gem](https://github.com/trkin/trk_datatables) that you
can use with trk_datatables npm package for easier usage of [Datatables js library](https://datatables.net)

It gives you one liner command to generate first page in html (so non-js
crawlers can see it), global search, filtering and sorting by one or more
columns, adding map and other complex listing based on GET params.

There are alternatives, for example:
* [jbox-web/ajax-datatables-rails](https://github.com/jbox-web/ajax-datatables-rails)
excellent gem but it's scope is only to produce JSON. I wanted to have server
side rendering and more advance listing

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

In datatable class you need to define three methods: `all_items`, `columns` and
`rows`.

```
# app/datatables/posts_datatable.rb
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
        @view.link_to(post.title, post),
        post.user&.email,
      ]
    end
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
    render json: PostsDatatable.new(view_context).as_json
  end
end
```

In controller add a route to `:search`

```
# config/routes.rb
Rails.application.routes.draw do
  resources :posts do
    colletion do
      get :search
    end
  end
end
```

And finally in a view, use `render_html` to have first page show up prerendered

```
# app/views/posts/index.html
<h1>Posts</h1>
<%= @datatable.render_html %>
```

## Configuration

### Global search

There are two types of search: global (search all columns) and column search
(search is done for specific columns).

For global search any type of a column is casted to a string and we use `ILIKE`
(ie `.matches`).

You can add more columns to global search by overriding `global_search_columns`
method.

```
class PostsDatatable < TrkDatatables::ActiveRecord
  def global_search_columns
    # those fields will be used only to match global search
    %w[posts.body users.name]
  end
end
```

### Column search

For column search when search string does not contain Separator (` - `) than
all columns are casted to string and `ILIKE` is perfomed.

When search contains Separator and for column_type_in_db as one of the:
`:date`, `:datetime`, `:integer` and `:float` than `BETWEEN` is perfomed. For
other column_type_in_db we use `ILIKE`.

For columns `:date` and `:datetime` bootstrap datepicker will be automatically
loaded.

### Custom column search

You can use column_option `search: :select` or `search: :multiselect` with
`options: [['name1', 'value1']]` so select box will be loaded and
match if `col IN (value1|value2)`. If column_type_in_db is :integer (when
you use enum in Rails than it will convert to `col IN (integer1|integer2)`.

You can use column_option `search: :checkbox` so for column_type_in_db `:boolean`
it will provide checkbox. For other column_type_in_db it will match if value is
NULL or NOT NULL.

## Params

To set parameters that you can use for links to set column search value, use this helpers

```
PostsDatatable.params_set('users.id': 1, 'posts.body': 'Hi')
# in view
link_to 'Posts for my@email.com and my_title', posts_path(PostsDatatable.params_set('users.email' => 'my@email.com', 'posts.title': 'my_title').merge(user_id: 1))
# will generate
```

If you need, you can fetch params with this helper

```
PostsDatatable.param_get('users.email', params)
```

## Saved Preferences (optional)

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

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
