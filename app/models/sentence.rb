class Sentence
  def initialize(value)
    @value = value
  end

  def tokenize
    @value.downcase.scan(/\w+|[[:punct:]]/).map do |value|
      Token.new(
        value: value,
        annotations: {
          context: @value
        }
      )
    end
  end

  def to_s
    @value
  end
end
