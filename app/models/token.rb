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

  scope :related, ->(token) do
    where(id: token.related.map(&:id))
  end

  after_initialize do
    self.annotations ||= {
      "contexts" => [],
      "part_of_speech_counts" => {}
    }
  end

  def edges
    Edge.where(token_1: self, distance: 1).order("count desc")
  end

  def related
    edges.map(&:token_2)
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

  def contexts
    self.annotations["contexts"] || []
  end

  def followers(pos = nil)
    if pos
      edges.common.part_of_speech(pos)[0..999].map(&:token_2)
    else
      edges.common[0..999].map(&:token_2)
    end
  end

  def part_of_speech
    parts_of_speech.sample
  end

  def parts_of_speech
    part_of_speech_tags.map(&:part_of_speech)
  end
end
