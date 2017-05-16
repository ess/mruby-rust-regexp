class RustRegexp
  @memo = {}

  attr_reader :source, :ignore_case, :multi_line

  def self.compile(*args)
    as = args.to_s
    unless @memo.key? as
      @memo[as] = self.new(*args)
    end
    @memo[as]
  end

  def self.oxidize(pattern)
    pattern.gsub('(?<', '(?P<')
  end

  def initialize(pattern, option = "")
    @source = pattern
    @ignore_case = option.include? 'i'
    @multi_line = option.include? 'm'
  end

  def match(string, position = 0)
    return nil if position >= string.length

    substring = string[position, string.length]
    submatches = self.class.get_submatches(
      self.class.oxidize(source),
      substring
    )

    return nil if submatches.empty?

    match_data = self.class.set_last_match(
      RustMatchData.new(source, substring, submatches)
    )

    if block_given?
      yield(match_data)
    end

    match_data

  end

  def self.set_last_match(match_data)
    @last_match = match_data
  end

  def self.last_match
    @last_match
  end
end

class RustMatchData
  class Submatch
    attr_reader :front, :back, :content, :name

    def init(front, back, content, name)
      @front = front
      @back = back
      @content = content
      @name = name
    end

    def named?
      !name.nil?
    end
  end

  attr_reader :string, :regexp

  def initialize(regexp, string, submatches)
    @regexp = regexp
    @string = string

    submatches = submatches.map {|s| puts "s == '#{s}'" ; Submatch.new(*s)}

    # Always grab the first submatch, as it is the "main" match.
    record_submatch(submatches.shift)

    # Are there named submatches?
    named = submatches.any? {|s| s.named?}

    # Fun fact: to emulate Ruby's standard Regexp, we have to ignore unnamed
    # captures if there are any named captures.
    (named ? submatches.select {|s| s.named?} : submatches).each do |submatch|
      record_submatch(submatch)
    end
  end

  def [](*args)
    key = args.first

    if args.size == 1 && (key.is_a? String)

      retval = submatches.find {|submatch| submatch.name == key}
      raise IndexError if retval.nil?
      return retval
    end

    to_a[*args]
  end

  def to_a
    submatches.map(&:content)
  end

  def captures
    a = to_a
    a.shift
    a
  end

  private
  def submatches
    @submatches ||= []
  end

  def record_submatch(submatch)
    submatches.push(submatch)
  end

  def record_named_submatch(submatch)
    named_submatches[submatch.name] ||= submatch
  end
end
