require 'test_helper.rb'

class RenderHtmlTest < Minitest::Test
  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.verified': {},
        'posts.published_on': {title: 'Released'},
        'posts.status': {order: false, search: false},
        '': {title: 'Links'},
      }
    end

    def rows(filtered)
      filtered.map do |post|
        [
          post.title,
          post.verified ? 'Verified' : 'Not-verified',
          post.published_on,
          post.status,
          'my_link',
        ]
      end
    end
  end

  def test_render_basic
    Post.create title: 'Post1', status: :draft, published_on: '2020-01-01'
    Post.create title: 'Post2', status: :published, verified: true, published_on: '2020-10-10'
    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params PostsDatatable.param_set('posts.published_on', '2020')
    result = datatable.render_html 'link', class: 'blue'
    expected = <<~HTML
      <table class='table table-bordered table-striped blue' data-datatable='true' data-datatable-ajax-url='link' data-datatable-page-length='10' data-datatable-order='[[0,&quot;desc&quot;]]' data-datatable-total-length='2'>
        <thead>
          <tr>
            <th>Title</th>
            <th data-datatable-checkbox='true'>Verified</th>
            <th data-datatable-range='true' data-datatable-search-value='2020'>Released</th>
            <th data-searchable='false' data-orderable='false'>Status</th>
            <th data-searchable='false' data-orderable='false'>Links</th>

          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Post2</td>
            <td>Verified</td>
            <td>2020-10-10</td>
            <td>published</td>
            <td>my_link</td>

          </tr>
          <tr>
            <td>Post1</td>
            <td>Not-verified</td>
            <td>2020-01-01</td>
            <td>draft</td>
            <td>my_link</td>

          </tr>
        </tbody>
      </table>
    HTML
    assert_equal expected, result, result
  end

  class ActionDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.all
    end

    def columns
      {
        'posts.title': {},
        '': {order: false, search: false, title: "<a href='#' id='toggle-all-rows'>All</a>".html_safe},
      }
    end

    def rows(filtered)
      filtered.map do |post|
        [
          post.title,
          'checkbox',
        ]
      end
    end
  end

  def test_render_actions
    Post.create title: 'Post1'
    datatable = ActionDatatable.new TrkDatatables::DtParams.sample_view_params
    result = datatable.render_html 'link'
    expected = <<~HTML
      <table class='table table-bordered table-striped' data-datatable='true' data-datatable-ajax-url='link' data-datatable-page-length='10' data-datatable-order='[[0,&quot;desc&quot;]]' data-datatable-total-length='1'>
        <thead>
          <tr>
            <th>Title</th>
            <th data-searchable='false' data-orderable='false'><a href='#' id='toggle-all-rows'>All</a></th>

          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Post1</td>
            <td>checkbox</td>

          </tr>
        </tbody>
      </table>
    HTML
    assert_equal expected.split.join, result.split.join, result
  end

  class MultiselectsDatatable < TrkDatatables::ActiveRecord
    def columns
      {
        'posts.title': {},
        'posts.status': {title: 'POS', select_options: Post.statuses},
      }
    end
  end

  def test_render_select
    datatable = MultiselectsDatatable.new TrkDatatables::DtParams.sample_view_params columns: {'1': {search: {value: 'published|promoted'}}}
    # Post.statuses.values_at(:published, :promoted).join(TrkDatatables::MULTIPLE_OPTION_SEPARATOR),
    render_html = TrkDatatables::RenderHtml.new 'link', datatable, class: 'blue'
    expected = <<~HTML
      <thead>
        <tr>
          <th>Title</th>
          <th data-datatable-search-value='published|promoted' data-datatable-multiselect='[{&quot;key&quot;:&quot;draft&quot;,&quot;value&quot;:0},{&quot;key&quot;:&quot;published&quot;,&quot;value&quot;:1},{&quot;key&quot;:&quot;promoted&quot;,&quot;value&quot;:2},{&quot;key&quot;:&quot;landing&quot;,&quot;value&quot;:3}]'>POS</th>

        </tr>
      </thead>
    HTML
    result = render_html.thead
    assert_equal expected.strip, result
  end

  class ColumnIsHashDatatable < TrkDatatables::ActiveRecord
    def columns
      %i[posts.title]
    end

    def all_items
      p = Post.create
      Post.where(id: p.id)
    end

    def rows(filtered)
      filtered.map do |post|
        [
          {id: post.id},
        ]
      end
    end
  end

  def test_table_column_content_is_a_hash
    datatable = ColumnIsHashDatatable.new TrkDatatables::DtParams.sample_view_params
    render_html = TrkDatatables::RenderHtml.new 'link', datatable
    expected = <<~HTML
      <table class='table table-bordered table-striped ' data-datatable='true' data-datatable-ajax-url='link' data-datatable-page-length='10' data-datatable-order='[[0,&quot;desc&quot;]]' data-datatable-total-length='1'>
        <thead>
          <tr>
            <th>Title</th>

          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{:id=&gt;2}</td>

          </tr>
        </tbody>
      </table>
    HTML
    result = render_html.table_tag_server
    assert_equal expected, result
  end
end
