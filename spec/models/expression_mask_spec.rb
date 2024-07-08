require "rails_helper"

RSpec.describe ExpressionMask do
  before do
    Token.create!(value: "the", annotations: { part_of_speech: "article" })
    Token.create!(value: "dog", annotations: { part_of_speech: "noun" })
    Token.create!(value: "sits", annotations: { part_of_speech: "verb" })
    Token.create!(value: ".", annotations: { part_of_speech: "period" })
  end

  it "works" do
    expression_mask = ExpressionMask.new("article noun verb period", anchor_word: "dog")
    expect(expression_mask.evaluate).to eq("the dog sits.")
  end

  describe "#fill_triplet" do
    it "works" do
      i = Token.create!(value: "i", annotations: { part_of_speech: "pronoun" })

      triplet = Triplet.create!(
        token: i,
        text: "i love sausage",
        mask: "pronoun verb noun"
      )

      expression_mask = ExpressionMask.new("pronoun verb noun adverb", anchor_word: "pizza")
      expect(expression_mask.triplets[0]).to eq(triplet)
    end
  end
end
