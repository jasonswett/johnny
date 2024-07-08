class ExpressionMask
  VALID_MASKS = [
    "pronoun verb noun period",
    "pronoun verb noun conjunction article noun period",
    "pronoun adverb verb acticle adjective noun period",
    "pronoun verb pronoun period",
    "noun conjunction noun verb article noun period",
    "personal_pronoun adjective noun and personal_pronoun adjective noun verb noun period",
    "article noun comma article noun conjunction article noun verb noun period",
    "article adjective noun comma noun conjunction noun verb noun period",
    "pronoun conjunction pronoun verb period",
    "adverb comma noun verb preposition adjective noun period",
    "preposition article adjective noun comma preposition noun comma pronoun verb adverb period",
    "preposition noun comma adjective noun verb adjective noun period",
    "adjective conjunction adjective comma noun verb noun period",

    "noun verb adjective exclamation_point",
    "verb adverb exclamation_point",

    "verb adjective noun adjective question_mark",
    "verb noun conjunction noun verb noun question_mark",
    "verb pronoun verb noun conjunction adjective adjective noun question_mark",
    "verb noun adjective question_mark",
  ]

  FREQUENCY_THRESHOLD = 1000

  def initialize(mask, anchor_token:, related_tokens:)
    @mask = mask
    @parts_of_speech = mask.split
    @anchor_token = anchor_token
    @related_tokens = related_tokens
  end

  def self.generate_sentence(anchor_token:, related_tokens:)
    new(VALID_MASKS.sample, anchor_token:, related_tokens:).evaluate
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
    Token.part_of_speech(part_of_speech)
  end
end
