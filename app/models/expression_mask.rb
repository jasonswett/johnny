class ExpressionMask
  VALID_MASKS = [
    "preposition definite_article noun comma personal_pronoun verb indefinite_article adjective noun period",
    "adverb_place comma preposition indefinite_article noun comma personal_pronoun verb indefinite_article noun period",
    "personal_pronoun adverb_time verb definite_article noun period",
    "definite_article noun verb_stative adjective period",
    "definite_article noun verb_stative preposition indefinite_article noun period",
    "personal_pronoun verb_stative adjective period",
    "personal_pronoun verb_stative indefinite_article adjective noun period",
    "personal_pronoun verb_stative preposition indefinite_article noun period",
    "personal_pronoun verb preposition indefinite_article noun period",
    "verb_stative personal_pronoun adjective question_mark",
    "verb_stative indefinite_article noun adjective question_mark",
    "preposition definite_article noun comma preposition indefinite_article adjective noun comma possessive_pronoun adverb_time verb definite_article noun period",
    "preposition definite_article noun personal_pronoun verb period",
    "definite_article noun comma definite_article noun coordinating_conjunction definite_article noun verb_auxiliary verb_stative adjective period",
    "definite_article noun verb_auxiliary adverb verb preposition definite_article noun period",
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
    Sentence.new(expression).tokens.map(&:pull).map(&:part_of_speech)
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
    Token.part_of_speech(part_of_speech)
  end
end
