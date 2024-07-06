class Token < ApplicationRecord
  attr_reader :parts_of_speech

  PARTS_OF_SPEECH = {
    personal_pronoun: %w(my your our their his her),
    article: %w(the a an)
  }

  PART_OF_SPEECH_CONFIDENCE_THRESHOLD = 0.5

  scope :most_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  scope :part_of_speech, ->(value) do
    where("annotations->>'part_of_speech' = ?", value)
      .order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  after_initialize do
    self.annotations ||= {
      "contexts" => []
    }

    @parts_of_speech = {}
  end

  def add_context(value)
    self.annotations["contexts"] ||= []
    self.annotations["contexts"] << value
  end

  def serialize
    {
      value: value,
      annotations: annotations || {}
    }
  end

  def to_s
    value
  end

  def details
    [
      value,
      annotations
    ].join("\n")
  end

  def self.label_parts_of_speech
    tokens = {}

    puts "Detecting articles and personal pronouns..."
    all.most_frequent_first.find_each do |token|
      token.articles_and_personal_pronouns
      token.annotations["part_of_speech"] = token.part_of_speech
      tokens[token.value] = token
    end

    puts "Detecting nouns..."
    tokens.each do |_, token|
      token.nouns
      token.annotations["part_of_speech"] = token.part_of_speech
      tokens[token.value] = token
    end

    puts "Detecting adjectives..."
    tokens.each do |_, token|
      token.adjectives(tokens)
      token.annotations["part_of_speech"] = token.part_of_speech
      token.annotations["parts_of_speech"] = token.parts_of_speech
      token.save!
    end
  end

  def articles_and_personal_pronouns
    self.annotations["contexts"].each do |context|
      if PARTS_OF_SPEECH[:personal_pronoun].include?(value)
        @parts_of_speech[:personal_pronoun] ||= 0
        @parts_of_speech[:personal_pronoun] += 1
      end

      if PARTS_OF_SPEECH[:article].include?(value)
        @parts_of_speech[:article] ||= 0
        @parts_of_speech[:article] += 1
      end
    end

    @parts_of_speech
  end

  def nouns
    self.annotations["contexts"].each do |context|
      sentence_tokens = Sentence.new(context).tokens

      sentence_tokens.each_with_index do |token, index|
        next if index == 0 || token.value != self.value

        previous_token = sentence_tokens[index - 1]

        if PARTS_OF_SPEECH[:personal_pronoun].include?(previous_token.value) ||
            PARTS_OF_SPEECH[:article].include?(previous_token.value)
          @parts_of_speech[:noun] ||= 0
          @parts_of_speech[:noun] += 1
        end
      end
    end

    @parts_of_speech
  end

  def adjectives(tokens)
    self.annotations["contexts"].each do |context|
      sentence_tokens = Sentence.new(context).tokens

      sentence_tokens.each_with_index do |token, index|
        next if index == 0 || index >= (sentence_tokens.length - 1) || token.value != self.value

        previous_token = tokens[sentence_tokens[index - 1].value]
        next_token = tokens[sentence_tokens[index + 1].value]

        if previous_token && previous_token.annotations["part_of_speech"] == "article" &&
            next_token && next_token.annotations["part_of_speech"] == "noun"
          @parts_of_speech[:noun] ||= 0
          @parts_of_speech[:noun] -= 0.01
          @parts_of_speech[:adjective] ||= 0
          @parts_of_speech[:adjective] += 1
        end
      end
    end

    @parts_of_speech
  end

  def part_of_speech
    frontrunner = parts_of_speech.max_by { |_, count| count }
    return unless frontrunner.present?

    name, count = frontrunner
    name.to_s
  end

  def context_count
    self.annotations["contexts"].count
  end
end
