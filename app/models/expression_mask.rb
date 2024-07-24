class ExpressionMask
  VALID_MASKS = [
    "IN DT NN comma PRP VB DT JJ NN period",
    "RB comma IN DT NN comma PRP VB DT NN period",
    "PRP RB VB DT NN period",
    "DT NN VBZ JJ period",
    "DT NN VBZ IN DT NN period",
    "PRP VBZ JJ period",
    "PRP VBZ DT JJ NN period",
    "PRP VBZ IN DT NN period",
    "PRP VB IN DT NN period",
    "IN DT NN PRP VB period",
    "DT NN comma DT NN CC DT NN VBZ JJ period",
    "DT NN MD RB VB IN DT NN period",
    "WP VBZ NN question_mark",
    "MD DT NN VB question_mark",
    "DT NN VBZ JJ CC DT NN VBZ JJ period",
    "PRP VBZ DT NN CC DT NN period",
    "DT NN VBZ JJ CC JJ period",
    "DT NN VBZ IN DT NN period",
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

  def self.parts_of_speech(expression)
    Sentence.new(expression)
      .tokens
      .map(&:pull)
      .map { |t| t.part_of_speech || "X" }
  end

  def self.sample_contexts(token)
    token.contexts
      .select { |c| c.length < 50 }
      .shuffle[0..9]
      .map { |c| ExpressionMask.parts_of_speech(c).join(" ") }
  end

  private

  def tokens
    @tokens = []

    @parts_of_speech.each_with_index do |part_of_speech, index|
      if index > 0 && @tokens[index - 1].present?
        @tokens << best_token_following(@tokens[index - 1], part_of_speech)
      else
        @tokens << (@related_tokens.part_of_speech(part_of_speech).sample || random_tokens(part_of_speech).sample)
      end
    end

    @tokens
  end

  def best_token_following(token, part_of_speech)
    follower_values = (token.followers || []).uniq

    @related_tokens.part_of_speech(part_of_speech).shuffle.each do |related_token|
      return related_token if follower_values.include?(related_token.value)
    end

    random_tokens(part_of_speech).shuffle.each do |random_token|
      return random_token if follower_values.include?(random_token.value)
    end

    random_tokens(part_of_speech).sample
  end

  def random_tokens(part_of_speech)
    Token.part_of_speech(part_of_speech).most_frequent_first
  end
end
