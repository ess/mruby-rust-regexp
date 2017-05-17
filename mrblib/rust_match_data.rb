class RustMatchData
  attr_reader :string, :regexp

  def initialize(regexp, string, submatches)
    @regexp = regexp
    @string = string

    submatches = submatches.map {|s| Submatch.new(*s)}

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

    if args.size == 1
      key = key.to_s if key.is_a?(Symbol)

      if (key.is_a? String)
        retval = submatches.find {|submatch| submatch.name == key}
        raise IndexError if retval.nil?
        return retval.content
      end
    end

    to_a[*args]
  end

  def begin(n)
    raise IndexError if n > submatches.size - 1 || n < 0

    submatches[n].front
  end

  def end(n)
    raise IndexError if n > submatches.size - 1 || n < 0

    submatches[n].back
  end

  def to_a
    submatches.map {|s| s.content}
  end

  def captures
    a = to_a
    a.shift
    a
  end

  def to_s
    to_a.first
  end

  def inspect
    m = [to_s.inspect]

    submatches[1 .. -1].each do |cap|
      m << "#{cap.named? ? cap.name : (captures.index(cap.content) + 1)}:#{cap.content.inspect}"
    end

    "#<RustMatchData #{m.join(' ')}>"
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

MatchData = RustMatchData unless Object.const_defined?(:MatchData)
