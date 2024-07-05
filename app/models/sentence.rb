class Sentence
  REGEX_PATTERN = /(?<=[.!?])\s+|\n/

  def initialize(value)
    @value = value
  end

  def tokens
    @value.downcase.scan(/\w+|[[:punct:]]/).map do |value|
      Token.new(value: value)
    end
  end

  def to_s
    @value
  end
end
