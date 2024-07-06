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

    self.annotations[:contexts].each do |context|
      if PARTS_OF_SPEECH[:personal_pronoun].include?(value)
        @parts_of_speech[:personal_pronoun] ||= 0
        @parts_of_speech[:personal_pronoun] += 1
      end
    end

    @parts_of_speech
  end
end
