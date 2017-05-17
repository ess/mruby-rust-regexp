prev_regexp = Regexp
Regexp = RustRegexp


class TestMrubyRustRegexp < MTest::Unit::TestCase

  def test_basic_match
    pattern = '^foo$'
    re = RustRegexp.new(pattern)

    assert_nil(re.match('bar'))
    assert_nil(re.match(' foo'))
    assert_nil(re.match('foo '))
  end

  def test_last_match
    RustRegexp.new('.*') =~ 'ginka'
    #RustRegexp.new('.*').match('ginka')
    assert_equal 'ginka', RustRegexp.last_match[0]

    RustRegexp.new('zzz') =~ 'ginka'
    #RustRegexp.new('zzz').match('ginka')
    assert_nil RustRegexp.last_match
  end

  def test_compile
    assert_equal RustRegexp.compile('.*'), RustRegexp.compile('.*')
  end

  def test_dup
    r1 = RustRegexp.new(".*")
    r2 = r1.dup
    assert_equal r1, r2
    assert_equal 'kawa', r2.match('kawa')[0]
  end

  def test_eqeq
    reg1 = reg2 = RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+")
    reg3 = RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+")
    reg4 = RustRegexp.new("(https://[^/]+)[-a-zA-Z0-9./]+")

    assert_true(reg1 == reg2 && reg1 == reg3 && !(reg1 == reg4))

    assert_false(RustRegexp.new("a") == "a")
  end

  def test_eqeqeq
    reg = RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+")
    assert_true reg === "http://example.com"
    assert_false reg === "htt://example.com"
  end

  def test_squiggle
    assert_equal(0, RustRegexp.new('.*') =~ 'akari')
    assert_equal(nil, RustRegexp.new('t') =~ 'akari')
  end

#assert("RustRegexp#casefold?", '15.2.15.7.6') do
  #assert_false RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+", RustRegexp::MULTILINE).casefold?
  #assert_true RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+", RustRegexp::IGNORECASE | RustRegexp::EXTENDED).casefold?
  #assert_true RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+", RustRegexp::MULTILINE | RustRegexp::IGNORECASE).casefold?
  #assert_false RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+").casefold?
  #assert_true RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+", true).casefold?
#end

  def test_match
    reg = RustRegexp.new("(https?://[^/]+)[-a-zA-Z0-9./]+")
    assert_false reg.match("http://masamitsu-murase.12345/hoge.html").nil?
    assert_nil reg.match("http:///masamitsu-murase.12345/hoge.html")
  end

  def test_source
    str = "(https?://[^/]+)[-a-zA-Z0-9./]+"
    reg = RustRegexp.new(str)

    reg.source == str
  end

#if RustRegexp.const_defined? :ASCII_RANGE
  #assert('RustRegexp#options (no options)') do
    #assert_equal RustRegexp::ASCII_RANGE | RustRegexp::POSIX_BRACKET_ALL_RANGE | RustRegexp::WORD_BOUND_ALL_RANGE, OnigRegexp.new(".*").options
  #end

  #assert('RustRegexp#options (multiline)') do
    #assert_equal RustRegexp::MULTILINE | RustRegexp::ASCII_RANGE | RustRegexp::POSIX_BRACKET_ALL_RANGE | OnigRegexp::WORD_BOUND_ALL_RANGE, OnigRegexp.new(".*", OnigRegexp::MULTILINE).options
  #end
#end

  def test_extended_patterns_no_flags
    [
      [ ".*", "abcd\nefg", "abcd" ],
      [ "^a.", "abcd\naefg", "ab" ],
      [ "^a.", "bacd\naefg", "ae" ],
      [ ".$", "bacd\naefg", "d" ]
    ].each do |reg, str, result|
      m = RustRegexp.new(reg).match(str)
      assert_equal result, m[0] if assert_false m.nil?
    end
  end

  def test_match_multiline
    patterns = [
      [ RustRegexp.new(".*", RustRegexp::MULTILINE), "abcd\nefg", "abcd\nefg" ]
    ]

    patterns.all?{ |reg, str, result| reg.match(str)[0] == result }
  end

  def test_match_ignorecase
    [
      [ "aBcD", "00AbcDef", "AbcD" ],
      [ "0x[a-f]+", "00XaBCdefG", "0XaBCdef" ],
      [ "0x[^c-f]+", "00XaBCdefG", "0XaB" ]
    ].each do |reg, str, result|
      m = RustRegexp.new(reg, RustRegexp::IGNORECASE|RustRegexp::EXTENDED).match(str)
      assert_equal result, m[0] if assert_false m.nil?
    end
  end

  def test_match_none_encoding
    assert_equal 2, /\x82/n =~ "あ"
  end

  def match_data_example
    RustRegexp.new('(\w+)(\w)').match('+aaabb-')
  end

  def mismatch_data_example
    RustRegexp.new('abc').match('z')
  end

  def test_match_data_ary_access
    m = match_data_example
    assert_equal 'aaabb', m[0]
    assert_equal 'aaab', m[1]
    assert_equal 'b', m[2]
    assert_nil m[3]

    m = RustRegexp.new('(?<name>\w\w)').match('aba')
    assert_raise(TypeError) { m[[]] }
    assert_raise(IndexError) { m['nam'] }
    assert_equal 'ab', m[:name]
    assert_equal 'ab', m['name']
    assert_equal 'ab', m[1]

    m = RustRegexp.new('(\w) (\w) (\w) (\w)').match('a b c d')
    assert_equal %w(a b c d), m[1..-1]
  end

  def test_match_data_begin
    m = match_data_example
    assert_equal 1, m.begin(0)
    assert_equal 1, m.begin(1)
    assert_raise(IndexError) { m.begin 3 }
  end

  def test_match_data_captures
    m = match_data_example
    assert_equal ['aaab', 'b'], m.captures

    m = RustRegexp.new('(\w+)(\d)?').match('+aaabb-')
    assert_equal ['aaabb', nil], m.captures
  end

  def test_match_data_end
    m = match_data_example
    assert_equal 6, m.end(0)
    assert_equal 5, m.end(1)
    assert_raise(IndexError) { m.end 3 }
  end

  def test_match_data_dup
    m = match_data_example
    c = m.dup
    assert_equal m.to_a, c.to_a
  end

  def test_match_data_length
    assert_equal 3, match_data_example.length
  end

  def test_match_data_offset
    assert_equal [1, 6], match_data_example.offset(0)
    assert_equal [1, 5], match_data_example.offset(1)
  end

  def test_match_data_post_match
    assert_equal '-', match_data_example.post_match
  end

  def test_match_data_pre_match
    assert_equal '+', match_data_example.pre_match
  end

  def test_match_data_size
    assert_equal 3, match_data_example.length
  end

  def test_match_data_string
    assert_equal '+aaabb-', match_data_example.string
  end

  def test_match_data_to_a
    assert_equal ['aaabb', 'aaab', 'b'], match_data_example.to_a
  end

  def test_match_data_to_s
    assert_equal 'aaabb', match_data_example.to_s
  end

  def test_match_data_regexp
    assert_equal '(\w+)(\w)', match_data_example.regexp.source
  end

  def test_invalid_regexp
    assert_raise(RegexpError) { RustRegexp.new '[aio' }
  end

  def test_invalid_argument
    assert_raise(ArgumentError) { "".sub(//) }
    assert_raise(ArgumentError) { "\xf0".gsub(/[^a]/,"X") }
  end

  prev_regexp = Regexp
  ::Regexp = RustRegexp

  def test_string_index
    assert_equal 0, 'abc'.index('a')
    assert_nil 'abc'.index('d')
    assert_equal 3, 'abcabc'.index('a', 1)
    assert_equal 1, "hello".index(?e)

    assert_equal 0, 'abcabc'.index(/a/)
    assert_nil 'abc'.index(/d/)
    assert_equal 3, 'abcabc'.index(/a/, 1)
    assert_equal 4, "hello".index(/[aeiou]/, -3)
    assert_equal 3, "regexpindex".index(/e.*x/, 2)
  end



## global variables
#assert('$~') do
  def test_dolla_squiggle
    m = match_data_example
    assert_equal m[0], $~[0]

    mismatch_data_example
    assert_nil $~
  end

  # Can't set this global yet
  #def test_dolla_amp
    #m = match_data_example
    #assert_equal m[0], $&

    #mismatch_data_example
    #assert_nil $&
  #end

#assert('$`') do
  #m = match_data_example
  #assert_equal m.pre_match, $`

  #mismatch_data_example
  #assert_nil $`
#end

#assert('$\'') do
  #m = match_data_example
  #assert_equal m.post_match, $'

  #mismatch_data_example
  #assert_nil $'
#end

#assert('$+') do
  #m = match_data_example
  #assert_equal m[-1], $+

  #mismatch_data_example
  #assert_nil $+
#end

#assert('$1 to $9') do
  #match_data_example
  #assert_equal 'aaab', $1
  #assert_equal 'b', $2
  #assert_nil $3
  #assert_nil $4
  #assert_nil $5
  #assert_nil $6
  #assert_nil $7
  #assert_nil $8
  #assert_nil $9

  #mismatch_data_example
  #assert_nil $1
  #assert_nil $2
  #assert_nil $3
  #assert_nil $4
  #assert_nil $5
  #assert_nil $6
  #assert_nil $7
  #assert_nil $8
  #assert_nil $9
#end

#assert('default RustRegexp.set_global_variables?') do
  #assert_true RustRegexp.set_global_variables?
#end

#assert('change set_global_variables') do
  #m = match_data_example
  #assert_equal m[0], $~[0]

  #RustRegexp.set_global_variables = false
  #assert_false RustRegexp.set_global_variables?

  ## global variables must be cleared when RustRegexp.set_global_variables gets change
  #assert_nil $~

  #match_data_example
  #assert_nil $~

  #RustRegexp.set_global_variables = true
#end

  ::Regexp = Object

  def test_rust_regexp_not_default
    match_data_example
    assert_nil $~
  end

  ::Regexp = prev_regexp

end

#prev_regexp = Regexp
#Regexp = RustRegexp

#assert('String#index') do
  #puts "holy fucking shitballs"
  #assert_equal 0, 'abc'.index('a')
  #assert_nil 'abc'.index('d')
  #assert_equal 3, 'abcabc'.index('a', 1)
  #assert_equal 1, "hello".index(?e)

  #assert_equal 0, 'abcabc'.index(/a/)
  #assert_nil 'abc'.index(/d/)
  #assert_equal 3, 'abcabc'.index(/a/, 1)
  #assert_equal 4, "hello".index(/[aeiou]/, -3)
  #assert_equal 3, "regexpindex".index(/e.*x/, 2)
#end

Regexp = prev_regexp

MTest::Unit.new.run
