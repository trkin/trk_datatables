module MiniTest::Assertions
  def assert_equal_with_message(exp, act, key)
    assert_equal exp, act, "Expected: #{exp.map(&key)}\n  Actual: #{act.map(&key)}"
  end
end
