class ExpressionMask
  VALID_MASKS = [
    "article adjective noun verb noun period",
    "noun comma noun and noun verb conjunction verb period",
    "pronoun verb noun period",
    "pronoun verb noun conjunction article noun period",
    "noun conjunction noun verb article noun period",
    "article noun comma article noun conjunction article noun verb noun period",
    "article noun comma noun conjunction noun verb noun period",
    "pronoun conjunction pronoun verb period",
    "adverb comma noun verb preposition noun period",
    "preposition article noun comma preposition noun comma pronoun verb adverb period",
    "preposition noun comma adjective noun verb adjective noun period",
    "adjective conjunction adjective comma noun verb noun period",

    "noun verb adjective exclamation_point",

    "verb adjective noun adjective question_mark",
    "verb noun conjunction noun verb noun question_mark",
  ]

  FREQUENCY_THRESHOLD = 1000

  def initialize(text, anchor_word:)
    @parts_of_speech = text.split
    @anchor_word = anchor_word
  end

  def evaluate
    tokens.map { |token| token ? token.value : "X" }
      .join(" ")
      .gsub(/\s+([.,!?])/, '\1')
  end

  def self.generate_sentence(anchor_word:)
    new(VALID_MASKS.sample, anchor_word:).evaluate
  end

  private

  def tokens
    @parts_of_speech.map do |part_of_speech|
      related_token(part_of_speech) || random_token(part_of_speech)
    end
  end

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
      .part_of_speech(part_of_speech)
      .limit(FREQUENCY_THRESHOLD)
      .sample
  end
end
