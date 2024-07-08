require "rails_helper"

RSpec.describe Corpus do
  describe "index" do
    it "does not create duplicates" do
      corpus = Corpus.new("the")
      expect { corpus.index }.to change { Token.count }.by(1)

      corpus = Corpus.new("the")
      expect { corpus.index }.not_to change { Token.count }
    end

    it "does not overwrite" do
      token = Token.create!(
        value: "water",
        annotations: {
          "contexts": ["I drank some water."]
        }
      )

      corpus = Corpus.new("water water water")
      expect { corpus.index }.not_to change { Token.count }

      expect(token.reload.annotations["contexts"]).to include("I drank some water.")
    end
  end

  describe "sanitization" do
    it "removes \r" do
      corpus = Corpus.new("This is a sentence\r")
      expect(corpus.sentences.map(&:to_s)).to match_array(["This is a sentence"])
    end
  end

  it "can be split into sentences" do
    corpus = Corpus.new("This is a sentence. This is another sentence.")

    expect(corpus.sentences.map(&:to_s)).to match_array(
      [
        "This is a sentence.",
        "This is another sentence."
      ]
    )
  end

  context "no space" do
    it "works" do
      corpus = Corpus.new("There is no space.No space at all.")

      expect(corpus.sentences.map(&:to_s)).to match_array(
        [
          "There is no space.",
          "No space at all."
        ]
      )
    end
  end

  context "wrap" do
    it "works" do
      corpus = Corpus.new("This sentence wraps\nacross two lines.")

      expect(corpus.sentences.map(&:to_s)).to match_array(
        ["This sentence wraps across two lines."]
      )
    end
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
