class Token < ApplicationRecord
  scope :most_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
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
end
