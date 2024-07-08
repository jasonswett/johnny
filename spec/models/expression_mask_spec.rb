require "rails_helper"

RSpec.describe ExpressionMask do
  before do
    Token.create!(value: "the", annotations: { part_of_speech: "article" })
    Token.create!(value: "dog", annotations: { part_of_speech: "noun" })
    Token.create!(value: "sits", annotations: { part_of_speech: "verb" })
    Token.create!(value: ".", annotations: { part_of_speech: "period" })
  end

  it "works" do
    expression_mask = ExpressionMask.new("article noun verb period", related_tokens: Token.none)
    expect(expression_mask.evaluate).to eq("the dog sits.")
  end
end
