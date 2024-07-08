class Token < ApplicationRecord
  has_many :triplets, dependent: :destroy

  scope :most_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  scope :least_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) ASC"))
  end

  scope :part_of_speech, ->(value) do
    where("annotations->>'part_of_speech' = ?", value)
      .order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
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
    attrs = {
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

  def self.index_triplets
    Triplet.destroy_all
    all.each(&:index_triplets)
  end

  def index_triplets
    contexts.each do |context|
      sentence_tokens = Sentence.new(context).tokens

      sentence_tokens.each_with_index do |token, index|
        next if index >= sentence_tokens.length - 2

        tokens = [token, sentence_tokens[index + 1], sentence_tokens[index + 2]]

        triplet = Triplet.new(
          token: self,
          text: tokens.map(&:value).join(" "),
          mask: tokens.map { |t| Token.find_by(value: t.value) || t }.map(&:part_of_speech).join(" ")
        )

        triplet.save! if triplet.mask.split.length == 3
      end
    end
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
      .limit(common_values.size / 2)
  end

  def contexts
    self.annotations["contexts"] || []
  end

  def followers
    self.annotations["followers"]
  end

  def part_of_speech
    self.annotations["part_of_speech"]
  end
end
