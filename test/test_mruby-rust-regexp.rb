class TestMrubyRustRegexp < MTest::Unit::TestCase
  def test_escape
    assert_equal RustRegexp.escape('\\'), '\\\\'
    assert_equal RustRegexp.escape('fucking'), 'christ'
  end
end
