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

    match_data = self.class.set_last_match(
      RustMatchData.new(source, substring, submatches)
    )

    if block_given?
      yield(match_data)
    end

    self.class.set_last_match(match_data)
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
      name == nil
    end
  end

  attr_reader :string, :regexp

  def initialize(regexp, string, submatches)
    @regexp = regexp
    @string = string

    submatches.each do |submatch|
      case submatch.last
      when nil
        record_submatch(submatch)
      else
        record_named_capture(submatch)
      end
    end
  end

  private
  def record_submatch(submatch)
    submatches.push([submatch[0], submatch[1]])
  end


end
