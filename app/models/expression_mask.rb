class ExpressionMask
  VALID_MASKS = [
    "DTC NN VBL JJ period",
    "DTC NN VBL JJ and JJ period",
  ]

  FREQUENCY_THRESHOLD = 1000

  def initialize(mask, related_tokens:)
    @mask = mask
    @parts_of_speech = mask.split
    @related_tokens = related_tokens
  end

  def self.generate_sentence(related_tokens:)
    new(VALID_MASKS.sample, related_tokens:).evaluate
  end

  def evaluate
    tokens.map { |token| token ? token.value : "X" }
      .join(" ")
      .gsub(/\s+([.,!?])/, '\1')
  end

  private

  def tokens
    @tokens = []

    @parts_of_speech.each_with_index do |part_of_speech, index|
      if index > 0 && @tokens[index - 1].present?
        @tokens << best_token_following(@tokens[index - 1], part_of_speech)
      else
        @tokens << Token.part_of_speech(part_of_speech).sample
      end
    end

    @tokens
  end

  def best_token_following(token, part_of_speech)
    tokens = token.followers.part_of_speech(part_of_speech)

    #raise "No token to follow \"#{token}\""

    tokens[0..4].sample || Token.part_of_speech(part_of_speech).sample
  end
end
