module MiniTest::Assertions
  def assert_equal_with_message(exp, act, key)
    message = "Expected: #{exp.map(&key)}\n  Actual: #{act.map(&key)}"
    message += "\n  to_sql: #{act.to_sql}" if act.respond_to?(:to_sql)
    assert_equal exp, act, message
  end
end
