require 'test_helper'

class TrkDatatablesBaseTest < Minitest::Test
  def view
    OpenStruct.new(
      params: {}
    )
  end

  class NotCompletedDatatable < TrkDatatables::Base; end

  class BlankDatatable < TrkDatatables::Base
    def columns
      {}
    end

    def rows(_)
      []
    end

    def all_items
      []
    end
  end

  def test_all_items_not_defined
    assert_raises(NotImplementedError) { NotCompletedDatatable.new(view).all_items }
  end

  def test_columns_not_defined
    assert_raises(NotImplementedError) { NotCompletedDatatable.new(view).columns }
  end

  def test_rows_not_defined
    assert_raises(NotImplementedError) { NotCompletedDatatable.new(view).rows nil }
  end

  def test_as_json
    blank = BlankDatatable.new(view)
    blank.stub :filter_by_search_all, [] do
      blank.stub :filter_by_columns, [] do
        blank.stub :order_and_paginate_items, [] do
          act = blank.as_json
          exp = {
            draw: 0,
            recordsTotal: 0,
            recordsFiltered: 0,
            data: [],
          }
          assert_equal exp, act
        end
      end
    end
  end
end
