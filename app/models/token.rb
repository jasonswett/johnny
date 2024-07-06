class Token < ApplicationRecord
  PARTS_OF_SPEECH = {
    personal_pronoun: %w(my your our their his her),
    article: %w(the a an)
  }

  PART_OF_SPEECH_CONFIDENCE_THRESHOLD = 0.5

  scope :most_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  after_initialize do
    self.annotations ||= {
      "contexts" => []
    }
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

  def parts_of_speech
    @parts_of_speech = {}
    self.annotations["contexts"] ||= []

    self.annotations["contexts"].each do |context|
      if PARTS_OF_SPEECH[:personal_pronoun].include?(value)
        @parts_of_speech[:personal_pronoun] ||= 0
        @parts_of_speech[:personal_pronoun] += 1
      end

      if PARTS_OF_SPEECH[:article].include?(value)
        @parts_of_speech[:article] ||= 0
        @parts_of_speech[:article] += 1
      end

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

  def part_of_speech
    frontrunner = parts_of_speech.max_by { |_, count| count }
    return unless frontrunner.present?

    name, count = frontrunner
    return unless count > context_count * PART_OF_SPEECH_CONFIDENCE_THRESHOLD

    name.to_s
  end

  def context_count
    self.annotations["contexts"].count
  end
end
