require 'test_helper.rb'

class RenderHtmlTest < Minitest::Test
  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.published_date': { title: 'Released' },
        'posts.status': { order: false, search: false },
      }
    end

    def rows(filtered)
      filtered.map do |post|
        [
          post.title,
          post.published_date,
          post.status,
        ]
      end
    end
  end

  def test_render_basic
    Post.create title: 'Post1', status: :draft
    Post.create title: 'Post2', status: :published, published_date: '2020-10-10'
    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params columns: { '1': { search: { value: '2020' } } }
    result = datatable.render_html 'link', class: 'blue'
    expected = <<~HTML
      <table class='table table-bordered table-striped blue' data-datatable='true' data-datatable-ajax-url='link' data-datatable-page-length='10' data-datatable-order='[[0,&quot;desc&quot;]]' data-datatable-total-length='2'>
        <thead>
          <tr>
            <th>Title</th>
            <th data-datatable-range='true' data-datatable-search-value='2020'>Released</th>
            <th data-searchable='false' data-orderable='false'>Status</th>

          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Post2</td>
            <td>2020-10-10</td>
            <td>published</td>

          </tr>
          <tr>
            <td>Post1</td>
            <td></td>
            <td>draft</td>

          </tr>
        </tbody>
      </table>
    HTML
    assert_equal expected.split.join, result.split.join, result
  end

  class ActionDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.all
    end

    def columns
      {
        'posts.title': {},
        '': { order: false, search: false, title: "<a href='#' id='toggle-all-rows'>All</a>".html_safe },
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
end
