class Token < ApplicationRecord
  PARTS_OF_SPEECH = {
    personal_pronoun: %w(my your their his her)
  }

  scope :most_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  def add_context(value)
    self.annotations ||= {}
    self.annotations[:contexts] ||= []
    self.annotations[:contexts] << value
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
    self.annotations ||= {}
    self.annotations[:contexts] ||= []

    self.annotations[:contexts].each do |context|
      if PARTS_OF_SPEECH[:personal_pronoun].include?(value)
        @parts_of_speech[:personal_pronoun] ||= 0
        @parts_of_speech[:personal_pronoun] += 1
      end
    end

    self.annotations[:contexts].each do |context|
      sentence_tokens = Sentence.new(context).tokens

      sentence_tokens.each_with_index do |token, index|
        next if index == 0 || token.value != self.value

        previous_token = sentence_tokens[index - 1]

        if PARTS_OF_SPEECH[:personal_pronoun].include?(previous_token.value)
          @parts_of_speech[:noun] ||= 0
          @parts_of_speech[:noun] += 1
        end
      end
    end

    @parts_of_speech
  end

  def part_of_speech
    frontrunners = parts_of_speech.max_by { |_, count| count }
    return unless frontrunners.present?
    frontrunners.first.to_s
  end
end
