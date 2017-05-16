class RustRegexp
  @memo = {}

  attr_reader :source

  def self.compile(*args)
    as = args.to_s
    unless @memo.key? as
      @memo[as] = self.new(*args)
    end
    @memo[as]
  end

  def initialize(pattern, option = nil)
    @source = pattern
    @option = 0
    @ignore_case = option.include? 'i'
    @multi_line = option.include? 'm'
  end

  def match(string, position = nil)
    matches = self.class.match(string)

    return nil if matches.empty?

    matches
  end
end

class RustMatchData
end
