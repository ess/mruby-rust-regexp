class RustRegexp
  IGNORECASE = 1
  EXTENDED = 2
  MULTILINE = 3

  @memo = {}

  attr_reader :source

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

  def self.quote(string)
    escape(string)
  end

  def self.try_convert(obj)
    begin
      obj.to_regexp
    rescue
      nil
    end
  end

  def initialize(pattern, mask = 0, kcode = nil)
    @source = pattern
    @mask = mask
    @kcode = kcode
  end

  def =~(string)
    m = self.match(string)
    m ? m.begin(0) : nil
  end

  def match(string, position = 0)
    return nil if position >= string.length

    substring = string[position, string.length]
    submatches = self.class.get_submatches(
      self.class.oxidize(source),
      substring
    )

    # The MRI Regexp docs say that last_match returns the match data for the
    # last successful match, but that isn't true. It returns the hard result
    # of the last match call.
    return self.class.set_last_match(nil) if submatches.empty?

    match_data = self.class.set_last_match(
      RustMatchData.new(source, substring, submatches)
    )

    if block_given?
      yield(match_data)
    end

    match_data

  end

  def ==(other)
    other.is_a?(self.class) && source == other.source
  end

  def ===(string)
    !match(string).nil?
  end

  def self.set_last_match(match_data)
    set_globals(match_data)
    @last_match = match_data
  end

  def self.last_match
    @last_match
  end

  def self.set_globals(match_data)
    $~ = match_data
    #$& = match_data[0]
  end

end

class String
  # ISO 15.2.10.5.5
  def =~(a)
    begin
      (a.class.to_s == 'String' ?  Regexp.new(a.to_s) : a) =~ self
    rescue
      false
    end
  end

  # redefine methods with oniguruma regexp version
  #[:sub, :gsub, :split, :scan].each do |v|
    #alias_method "string_#{v}".to_sym, v
    #alias_method v, "onig_regexp_#{v}".to_sym
  #end

  alias_method :old_slice, :slice
  alias_method :old_square_brancket, :[]

  def [](*args)
    return old_square_brancket(*args) unless args[0].class == Regexp

    if args.size == 2
      match = args[0].match(self)
      if match
        if args[1] == 0
          str = match[0]
        else
          str = match.captures[args[1] - 1]
        end
        return str
      end
    end

    match_data = args[0].match(self)
    if match_data
      result = match_data.to_s
      return result
    end
  end

  alias_method :slice, :[]

  def slice!(*args)
    if args.size < 2
      result = slice(*args)
      nth = args[0]

      if nth.class == Regexp
        lm = Regexp.last_match
        self[nth] = '' if result
        Regexp.last_match = lm
      else
        self[nth] = '' if result
      end
    else
      result = slice(*args)

      nth = args[0]
      len = args[1]

      if nth.class == Regexp
        lm = Regexp.last_match
        self[nth, len] = '' if result
        Regexp.last_match = lm
      else
        self[nth, len] = '' if result && nth != self.size
      end
    end

    result
  end

  alias_method :old_index, :index

  def index(pattern, pos=0)
    if pattern.class == Regexp
      str = self[pos..-1]
      if str
        if num = (pattern =~ str)
          if pos < 0
            num += self.size
          end
          return num + pos
        end
      end
      nil
    else
      self.old_index(pattern, pos)
    end
  end
end

Regexp = RustRegexp unless Object.const_defined?(:Regexp)
