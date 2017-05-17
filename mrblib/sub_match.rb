class Submatch
  attr_reader :front, :back, :content, :name

  def initialize(front, back, content, name)
    @front = front
    @back = back
    @content = content
    @name = name
  end

  def named?
    !name.nil?
  end
end
