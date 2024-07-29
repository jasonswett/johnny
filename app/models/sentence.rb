class Sentence < ApplicationRecord
  REGEX_PATTERN = /(?<=[.!?])\s*|\n/
  MAXIMUM_RELEVANT_DISTANCE = 5

  validates :value, presence: true, uniqueness: true

  after_initialize do
    self.value = self.value
      .gsub(/\s+/, ' ')
      .gsub(/['"“”\*\-\_]/, ' ')
      .strip
      .downcase
  end

  validate do
    unless self[:value].match?(/\s/)
      errors.add(:value, "must contain a space")
    end
  end

  def to_s
    value
  end

  def tokens
    @tokens ||= value.scan(/\w+|[[:punct:]]/).map do |value|
      Token.upsert_by_value(value)
    end
  end

  def edges
    @edges ||= edge_attributes
      .reject { |attr| attr[:distance] > MAXIMUM_RELEVANT_DISTANCE }
      .map do |attr|
        edge = Edge.find_or_initialize_by(attr.slice(:token_1_id, :token_2_id, :distance))
        edge.count += 1
        edge.save!
        edge
      end
  end

  def edge_attributes
    tokens.each_with_index.flat_map do |token_1, token_1_index|
      (token_1_index + 1..tokens.length - 1).map do |token_2_index|
        {
          token_1_id: token_1.id,
          token_2_id: tokens[token_2_index].id,
          distance: token_2_index - token_1_index
        }
      end
    end
  end
end
