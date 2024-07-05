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

  describe "#tokenize" do
    it "works" do
      corpus = Corpus.new("This is a sentence.")

      expect(corpus.tokenize.map(&:to_s)).to match_array(
        [
          "this",
          "is",
          "a",
          "sentence",
          "."
        ]
      )
    end
  end
end
