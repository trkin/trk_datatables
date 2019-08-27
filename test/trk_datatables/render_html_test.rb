require 'test_helper.rb'

class RenderHtmlTest < Minitest::Test
  class PostsDatatable < TrkDatatables::ActiveRecord
    def all_items
      Post.left_joins(:user)
    end

    def columns
      {
        'posts.title': {},
        'posts.status': { order: false, search: false },
        'users.email': { title: 'Imejl' },
      }
    end

    def rows(filtered)
      filtered.map do |post|
        [
          post.title,
          post.status,
          post.user&.email,
        ]
      end
    end
  end

  def test_render_basic
    Post.create title: 'Post1', status: :draft
    Post.create title: 'Post2', status: :published, user: User.create(email: 'my@email.com')
    datatable = PostsDatatable.new TrkDatatables::DtParams.sample_view_params
    result = datatable.render_html 'link', class: 'blue'
    expected = <<~HTML
      <table class='table table-bordered table-striped blue' data-datatable='true' data-datatable-ajax-url='link' data-datatable-page-length='10' data-datatable-order='[{"column_index":0,"direction":"desc"}]' data-datatable-total-length='2'>
        <thead>
          <tr>
            <th>Title</th>
            <th data-searchable='false' data-orderable='false'>Status</th>
            <th>Imejl</th>

          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Post2</td>
            <td>published</td>
            <td>my@email.com</td>

          </tr>
          <tr>
            <td>Post1</td>
            <td>draft</td>
            <td></td>

          </tr>
        </tbody>
      </table>
    HTML
    assert_equal expected.split.join, result.split.join, result
  end
end
