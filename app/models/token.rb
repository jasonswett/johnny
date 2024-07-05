class Token < ApplicationRecord
  scope :most_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  def to_s
    value
  end
end
