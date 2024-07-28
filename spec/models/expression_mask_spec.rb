require "rails_helper"

RSpec.describe ExpressionMask do
  before do
    the = Token.create!(value: "the")
    PartOfSpeechTag.create!(token: the, part_of_speech: "article")

    dog = Token.create!(value: "dog")
    PartOfSpeechTag.create!(token: dog, part_of_speech: "noun")

    sits = Token.create!(value: "sits")
    PartOfSpeechTag.create!(token: sits, part_of_speech: "verb")

    period = Token.create!(value: ".")
    PartOfSpeechTag.create!(token: period, part_of_speech: "period")
  end

  it "works" do
    # twice because min count is 2
    Sentence.new("the dog sits.").edges
    Sentence.new("the dog sits.").edges

    expression_mask = ExpressionMask.new("article noun verb period", related_tokens: Token.none)
    expect(expression_mask.evaluate).to eq("the dog sits.")
  end
end
