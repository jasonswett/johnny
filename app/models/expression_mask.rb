class ExpressionMask
  VALID_MASKS = [
    "PRPS MD VB IN DTC NN period",
    "PRPS MD VB DTC NN period",
    "PRPS MD RB VB DTC NN period",
    "PRPS MD VB DTC NN and PRPS MD VB DTC NN period",
    "PRPS MD VB PRPS period",
    #"DTC NN VBL JJ period",
    #"DTC NN VBL DTC JJ NN period",
    #"VBL DTC NN JJ question_mark",
    #"PRPS VBL DTC JJ NN period",
    #"PRPS MD VB period",
    #"PRPS VBL DTC NN period IN DTC NN.",
    #"PRPS VBL IN DTC NN period",
    #"DTC JJR VBL NN period",
  ]

  def initialize(mask)
    @mask = mask
    @parts_of_speech = mask.split
  end

  def self.generate_sentence
    new(VALID_MASKS.sample).evaluate
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
    tokens = token.followers(part_of_speech)

    #raise "No token to follow \"#{token}\""

    tokens.sample || Token.part_of_speech(part_of_speech).sample.tap { |t| t.value += "*" }
  end
end
