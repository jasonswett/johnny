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

  def initialize(text, anchor_word:)
    @parts_of_speech = text.split
    @anchor_word = anchor_word
  end

  def self.generate_sentence(anchor_word:)
    new(VALID_MASKS.sample, anchor_word:).evaluate
  end

  def evaluate
    tokens.map { |token| token ? token.value : "X" }
      .join(" ")
      .gsub(/\s+([.,!?])/, '\1')
  end

  def triplets
    @parts_of_speech.each_with_index.map do |part_of_speech, index|
      mask = [
        part_of_speech,
        @parts_of_speech[index + 1],
        @parts_of_speech[index + 2],
      ].join(" ")

      Triplet.find_by(mask:)
    end
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
