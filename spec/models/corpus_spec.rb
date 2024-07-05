require "rails_helper"

RSpec.describe Corpus do
  it "can be split into sentences" do
    corpus = Corpus.new("This is a sentence. This is another sentence.")

    expect(corpus.sentences.map(&:to_s)).to match_array(
      [
        "This is a sentence.",
        "This is another sentence."
      ]
    )
  end
end
