require "rails"
require "test_helper"
require "generators/trk_datatables/trk_datatables_generator"

ROOT_DIR = File.expand_path(".")

class TrkDatatablesGeneratorTest < Rails::Generators::TestCase
  tests TrkDatatablesGenerator
  destination "#{ROOT_DIR}/tmp/generators"
  setup :prepare_destination

  test "generate datatable" do
    assert_nothing_raised do
      run_generator %w[dummy]

      assert_file "app/datatables/dummy_datatable.rb" do |file|
        assert_match(/class DummyDatatable < TrkDatatables::ActiveRecord/, file)

        assert_instance_method :columns, file do |columns|
          assert_equal({}, YAML.safe_load(columns))
        end
        assert_instance_method :all_items, file do |all_items|
          assert_match(/Dummy\.all/, all_items)
        end
        assert_instance_method :rows, file do |rows|
          assert_match(/filtered\.map do |dummy|/, rows)
        end
      end

      assert_no_file "spec/datatables/dummy_datatable_spec.rb"
      assert_no_file "spec/datatables/dummy_datatable_test.rb"
    end
  end

  test "generate rspec for datatable" do
    assert_nothing_raised do
      run_generator %w[dummy --rspec]

      assert_file "spec/datatables/dummy_datatable_spec.rb" do |file|
        assert_match(/RSpec.describe DummyDatatable/, file)
        assert_match(/DummyDatatable\.new/, file)
        assert_match(/get dummies_path/, file)
        assert_match(/post search_dummies_path/, file)
      end
      assert_no_file "spec/datatables/dummy_datatable_test.rb"
    end
  end

  test "generate minitest for datatable" do
    assert_nothing_raised do
      run_generator %w[dummy --minitest]

      assert_file "spec/datatables/dummy_datatable_test.rb" do |file|
        assert_match(/class DummyDatatableTest < ActionDispatch::IntegrationTest/, file)
        assert_match(/DummyDatatable\.new/, file)
        assert_match(/get dummies_path/, file)
        assert_match(/post search_dummies_path/, file)
      end
      assert_no_file "spec/datatables/dummy_datatable_spec.rb"
    end
  end
end
