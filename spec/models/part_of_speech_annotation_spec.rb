require "rails_helper"

RSpec.describe PartOfSpeechAnnotation do
  context "no contexts" do
    it "works" do
      token = Token.create!(value: "my")
      PartOfSpeechAnnotation.high_certainty_parts_of_speech([token])
      expect(token.annotations["part_of_speech_counts"]).to eq({})
    end
  end

  context "noun followed by article" do
    it "works" do
      token = Token.new(value: "world")
      token.add_context("The world can wait.")
      token.add_context("The world is yours.")
      token.add_context("You're the most beautiful sausage in the world.")

      PartOfSpeechAnnotation.nouns([token])
      expect(token.annotations["part_of_speech_counts"]).to eq("noun" => 3)
    end
  end

  context "end" do
    it "works" do
      token = Token.new(value: "big")
      token.add_context("I pet the big")

      PartOfSpeechAnnotation.adjectives([token])
      expect(token.annotations["part_of_speech_counts"]).to eq({})
    end
  end

  context "adjective" do
    let!(:tokens) do
      {
        "the" => Token.create!(
          value: "the",
          annotations: { part_of_speech: "definite_article" }
        ),
        "a" => Token.create!(
          value: "a",
          annotations: { part_of_speech: "indefinite_article" }
        ),
        "dog" => Token.create!(
          value: "dog",
          annotations: { part_of_speech: "noun" }
        ),
        "man" => Token.create!(
          value: "man",
          annotations: { part_of_speech: "noun" }
        ),
        "burger" => Token.create!(
          value: "burger",
          annotations: { part_of_speech: "noun" }
        )
      }
    end

    it "works" do
      token = Token.new(value: "big")
      token.add_context("I pet the big dog.")
      token.add_context("The big man ate a big burger.")

      PartOfSpeechAnnotation.adjectives([token])

      expect(token.annotations["part_of_speech_counts"]["adjective"]).to eq(6)
      expect(token.part_of_speech).to eq("adjective")
    end
  end

  context "article" do
    it "works" do
      token = Token.new(value: "the")
      token.add_context("The world can wait.")
      token.add_context("The world is yours.")
      token.add_context("You're the most beautiful sausage in the world.")

      PartOfSpeechAnnotation.high_certainty_parts_of_speech([token])
      expect(token.part_of_speech).to eq("definite_article")
    end
  end

  context "personal pronoun" do
    it "works" do
      token = Token.new(value: "my")
      token.add_context("my bologna has a first name.")
      token.add_context("my goodness, you're enormous!")

      PartOfSpeechAnnotation.high_certainty_parts_of_speech([token])
      expect(token.annotations["part_of_speech_counts"]).to eq("possessive_pronoun" => 200)
    end

    it "does not overwrite other annotations" do
      token = Token.new(value: "my")
      token.annotations["frequency"] = 100
      PartOfSpeechAnnotation.high_certainty_parts_of_speech([token])
      expect(token.annotations["frequency"]).to eq(100)
    end
  end

  context "noun" do
    it "works" do
      token = Token.new(value: "truck")
      token.add_context("my truck is blue.")
      token.add_context("get out of my truck.")
      token.add_context("your truck is okay")

      PartOfSpeechAnnotation.nouns([token])
      expect(token.annotations["part_of_speech_counts"]).to eq("noun" => 3)
    end
  end
end
