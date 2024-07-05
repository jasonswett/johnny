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

  context "question mark" do
    it "works" do
      corpus = Corpus.new("Will this work? I hope so.")

      expect(corpus.sentences.map(&:to_s)).to match_array(
        [
          "Will this work?",
          "I hope so."
        ]
      )
    end
  end

  context "exclamation point" do
    it "works" do
      corpus = Corpus.new("Dear God! I hope this works.")

      expect(corpus.sentences.map(&:to_s)).to match_array(
        [
          "Dear God!",
          "I hope this works."
        ]
      )
    end
  end

  context "newline" do
    it "works" do
      corpus = Corpus.new("No periods here\nJust newlines")

      expect(corpus.sentences.map(&:to_s)).to match_array(
        [
          "No periods here",
          "Just newlines"
        ]
      )
    end
  end

  describe "#tokens" do
    it "works" do
      corpus = Corpus.new("This is a sentence.")

      expect(corpus.tokens.map(&:to_s)).to match_array(
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
