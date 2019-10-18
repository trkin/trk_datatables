module TrkDatatables
  module Generators
    class TrkDatatablesGenerator < Rails::Generators::NamedBase
      # we can call with `rails g trk_datatables` instead of: `rails g trk_datatables:trk_datatables`
      namespace 'trk_datatables'
      source_root File.expand_path('../templates', __dir__)

      desc 'Generates datatables file for a give NAME'
      def create
        begin
          class_name.constantize
          @trk_class_name = "#{class_name.pluralize}Datatable"
          @trk_file_name = "#{plural_name}_datatable"
        rescue NameError => e
          Rails.logger.info e.message
          @skip_model = true
          @trk_class_name = "#{class_name}Datatable"
          @trk_file_name = "#{singular_name}_datatable"
        end

        template 'trk_datatable.rb', "app/datatables/#{@trk_file_name}.rb"

        say <<~TEXT
          ======================================================================
          You can use in your controller

          # app/controllers/#{plural_name}_controller.rb
          class #{class_name}Controller < ApplicationController
            def index
              @datatable = #{@trk_class_name}.new view_context
            end

            def search
              render json: #{@trk_class_name}.new(view_context)
            end
          end

          In your views mkdir app/views/#{plural_name}
          # app/views/#{plural_name}/index.html
          <h1>#{class_name.pluralize}</h1>
          <%= @datatable.render_html search_#{plural_name}_path(format: :json) %>

          And in routes

          # config/routes.rb
          Rails.application.routes.draw do
            resources :#{plural_name} do
              collection do
                post :search
              end
            end
          end
          ======================================================================
        TEXT
      end
    end
  end
end
