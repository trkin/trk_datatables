module TrkDatatables
  module Generators
    class TrkDatatablesGenerator < Rails::Generators::NamedBase
      MissingModelError = Class.new(Thor::Error)
      # we can call with `rails g trk_datatables` instead of: `rails g trk_datatables:trk_datatables`
      namespace 'trk_datatables'
      source_root File.expand_path('../templates', __dir__)

      desc 'Generates datatables file for a give NAME'
      def create
        begin
          class_name.constantize
        rescue NameError => e
          raise MissingModelError, e.message
        end

        template 'trk_datatable.rb', "app/datatables/#{plural_name}_datatable.rb"
      end
    end
  end
end
