# Trk Datatables

[trk_datatables](https://github.com/trkin/trk_datatables) is a gem that you can use with [Datatables](https://datatables.net) along with trk_datatables
npm package.
It can help generating first page in html (so non-js crawlers can see it),
filtering and sorting by one or more columns, adding map and other reporting
based on GET params.

There are alternatives, for example:
* [jbox-web/ajax-datatables-rails](https://github.com/jbox-web/ajax-datatables-rails)
excellent gem but it's scope is only to produce JSON. I wanted to have server
side rendering and more advance reporting


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

## Usage

In datatable class you need to define three methods: `all_items`, `columns` and
`rows`.
For example in Ruby on Rails:

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

## More examples

Search can be global ie search all columns or it can search for specific
column.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trkin/trk_datatables. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TrkDatatables project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/trkin/trk_datatables/blob/master/CODE_OF_CONDUCT.md).
