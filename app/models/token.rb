class Token < ApplicationRecord
  has_many :part_of_speech_tags

  scope :most_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  scope :least_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) ASC"))
  end

  scope :part_of_speech, ->(value) do
    joins(:part_of_speech_tags).where("part_of_speech_tags.part_of_speech = ?", value)
  end

  after_initialize do
    self.annotations ||= {
      "contexts" => [],
      "part_of_speech_counts" => {}
    }
  end

  def edges
    Edge.where(token_1: self).order("distance asc, count desc")
  end

  def self.f(v)
    find_by(value: v)
  end

  def self.upsert_by_value(value)
    new(value:).upsert_by_value
  end

  def upsert_by_value
    self.class.upsert({ value: }, unique_by: :value)
    self.class.f(value)
  end

  def add_context(value)
    self.annotations["contexts"] ||= []
    self.annotations["contexts"] << value
  end

  def serialize
    attrs = {
      value: value,
      annotations: annotations || {}
    }
  end

  def pull
    Token.find_by(value: value) || self
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

  def context_count
    self.annotations["contexts"].count
  end

  def self.related(tokens)
    common_values = tokens.flat_map do |token|
      context_tokens = Corpus.new(token.contexts.join(" ").downcase).tokens

      token_counts = Hash.new(0)

      context_tokens.each do |token|
        token_counts[token.value] += 1
      end

      token_counts.select { |_, count| count > 1 }.keys
    end

    Token.where(value: common_values)
      .least_frequent_first
      .limit(common_values.size / 3)
  end

  def contexts
    self.annotations["contexts"] || []
  end

  def followers
    Token.where(id: edges.map(&:token_2_id))
  end

  def part_of_speech
    parts_of_speech.sample
  end

  def parts_of_speech
    part_of_speech_tags.map(&:part_of_speech)
  end
end
