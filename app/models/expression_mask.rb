class ExpressionMask
  VALID_MASKS = [
    "personal_pronoun verb_action noun period",
    "personal_pronoun verb_action noun coordinating_conjunction definite_article noun period",
    "personal_pronoun adverb_manner verb_action indefinite_article adjective noun period",
    "personal_pronoun verb_stative personal_pronoun period",
    "noun coordinating_conjunction noun verb_transitive definite_article noun period",
    "personal_pronoun adjective noun coordinating_conjunction personal_pronoun adjective noun verb_action noun period",
    "definite_article noun comma indefinite_article noun coordinating_conjunction definite_article noun verb_action noun period",
    "definite_article adjective noun comma noun coordinating_conjunction noun verb_action noun period",
    "personal_pronoun coordinating_conjunction personal_pronoun verb_action period",
    "adverb_time comma noun verb_transitive preposition adjective noun period",
    "preposition definite_article adjective noun comma preposition noun comma personal_pronoun verb_adverb period",
    "preposition noun comma adjective noun verb_transitive adjective noun period",
    "adjective coordinating_conjunction adjective comma noun verb_action noun period",
    
    "noun verb_action adjective exclamation_point",
    "verb_action adverb_manner exclamation_point",
    
    "verb_action adjective noun adjective question_mark",
    "verb_transitive noun coordinating_conjunction noun verb_transitive noun question_mark",
    "verb_transitive personal_pronoun verb_transitive noun coordinating_conjunction adjective adjective noun question_mark",
    "verb_transitive noun adjective question_mark"
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
