class ExpressionMask
  VALID_MASKS = [
    "article adjective noun verb noun period",
    "verb noun adjective question_mark",
    "noun verb adjective exclamation_point",
    "personal_pronoun verb adverb verb noun period",
    "pronoun verb preposition article noun period",
    "article noun verb article adjective noun period",
    "adverb verb pronoun period",
    "conjunction noun verb adjective noun period",
    "preposition article noun verb pronoun period",
    "article noun verb conjunction noun verb period",
    "personal_pronoun verb preposition article adjective noun period",
    "pronoun verb article adjective noun period",
    "noun verb adverb period",
    "article noun adverb verb article noun period",
    "preposition article adjective noun verb noun period",
    "adjective noun comma article noun verb period",
    "personal_pronoun verb noun comma conjunction noun verb period",
    "noun verb adjective comma conjunction verb noun period",
    "verb article adjective noun comma and verb noun period",
    "adverb verb pronoun comma noun verb period",
    "preposition article noun comma pronoun verb adjective period",
    "article noun verb pronoun comma and verb noun period",
    "personal_pronoun verb noun comma conjunction verb adjective noun period",
    "noun comma verb article noun conjunction verb noun period",
    "adjective noun comma verb noun comma article noun period",
    "noun verb pronoun comma article adjective noun period",
    "article adjective noun comma noun verb period"
  ]

  FREQUENCY_THRESHOLD = 1000

  def initialize(text, anchor_word:)
    @parts_of_speech = text.split
    @anchor_word = anchor_word
  end

  def evaluate
    @parts_of_speech.map { |part_of_speech| related_token(part_of_speech) || random_token(part_of_speech) }
      .map { |token| token ? token.value : "?" }
      .join(" ")
      .gsub(/\s+([.,!?])/, '\1')
  end

  def self.generate_sentence(anchor_word:)
    new(VALID_MASKS.sample, anchor_word:).evaluate
  end

  private

  def related_token(part_of_speech)
    Token.where("value in (?)", related_words)
      .part_of_speech(part_of_speech)
      .sample
  end

  def related_words
    @related_words ||= Token.find_by(value: @anchor_word).related_words
  end

  def random_token(part_of_speech)
    Token.most_frequent_first
      .part_of_speech(part_of_speech)[0..FREQUENCY_THRESHOLD]
      .sample
  end
end
