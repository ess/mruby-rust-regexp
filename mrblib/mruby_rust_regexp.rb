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

  def initialize(pattern, option = nil)
    @source = pattern
    @ignore_case = option.include? 'i'
    @multi_line = option.include? 'm'
  end

  def match(string, position = 0)
    return nil if position >= string.length

    substring = string[position, string.length]
    submatches = self.class.get_submatches(source, substring)

    return nil if submatches.empty?

    match_data = RustMatchData.new(source, substring, submatches))

    if block_given?
      yield(match_data)
    end

    match_data
  end
end

class RustMatchData
  attr_reader :string, :regexp

  def initialize(regexp, string, submatches)
    @regexp = regexp
    @string = string

  end
end
