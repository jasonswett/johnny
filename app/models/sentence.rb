class Sentence
  def initialize(value)
    @value = value
  end

  def tokenize
    @value.downcase.scan(/\w+|[[:punct:]]/)
  end

  def to_s
    @value
  end
end
