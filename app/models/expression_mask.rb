class ExpressionMask
  VALID_MASKS = [
    "article adjective noun verb noun period"
  ]

  def initialize(text)
    @parts_of_speech = text.split
  end

  def evaluate
    @parts_of_speech.map { |part_of_speech| Token.part_of_speech(part_of_speech).sample }
      .map { |token| token ? token.value : "?" }
      .join(" ")
  end

  def self.generate_sentence
    new(VALID_MASKS.sample).evaluate
  end
end
