class Edge < ApplicationRecord
  belongs_to :token_1, class_name: "Token"
  belongs_to :token_2, class_name: "Token"
  validates :token_1_id, uniqueness: { scope: [:token_2_id, :distance] }

  scope :part_of_speech, ->(value) do
    joins("INNER JOIN part_of_speech_tags ON part_of_speech_tags.token_id = edges.token_2_id")
      .where("part_of_speech_tags.part_of_speech = ?", value)
  end

  def to_s
    [token_1, token_2, distance].join(" ")
  end

  def self.by_token_1_value(value)
    where(token_1:)
  end

  def self.by_token_2_value(value)
    where(token_2:)
  end
end
