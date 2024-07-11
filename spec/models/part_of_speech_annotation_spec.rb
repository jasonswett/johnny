require "rails_helper"

RSpec.describe PartOfSpeechAnnotation do
  context "no contexts" do
    it "works" do
      token = Token.create!(value: "my")
      PartOfSpeechAnnotation.exact_matches([token])
      expect(token.annotations["part_of_speech_counts"]).to eq({})
    end
  end

  context "words ending in ly" do
    it "works" do
      token = Token.new(value: "crappily")

      PartOfSpeechAnnotation.adverbs([token])
      expect(token.annotations["part_of_speech_counts"]).to eq("RB" => 2)
    end
  end

  context "noun followed by article" do
    it "works" do
      token = Token.new(value: "world")
      token.add_context("The world can wait.")
      token.add_context("The world is yours.")
      token.add_context("You're the most beautiful sausage in the world.")

      PartOfSpeechAnnotation.nouns([token])
      expect(token.annotations["part_of_speech_counts"]).to eq("NN" => 3)
    end
  end

  context "after auxilliary verb" do
    before do
      Token.create!(
        value: "could",
        annotations: { part_of_speech: "MD" }
      )

      Token.create!(
        value: "must",
        annotations: { part_of_speech: "MD" }
      )

      Token.create!(
        value: "will",
        annotations: { part_of_speech: "MD" }
      )
    end

    it "works" do
      token = Token.new(value: "go")
      token.add_context("We could go today.")
      token.add_context("You must go.")
      token.add_context("I will go.")

      PartOfSpeechAnnotation.verbs([token])
      expect(token.annotations["part_of_speech_counts"]).to eq("VB" => 6)
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
          annotations: { part_of_speech: "DT" }
        ),
        "a" => Token.create!(
          value: "a",
          annotations: { part_of_speech: "DT" }
        ),
        "dog" => Token.create!(
          value: "dog",
          annotations: { part_of_speech: "NN" }
        ),
        "man" => Token.create!(
          value: "man",
          annotations: { part_of_speech: "NN" }
        ),
        "burger" => Token.create!(
          value: "burger",
          annotations: { part_of_speech: "NN" }
        )
      }
    end

    it "works" do
      token = Token.new(value: "big")
      token.add_context("I pet the big dog.")
      token.add_context("The big man ate a big burger.")

      PartOfSpeechAnnotation.adjectives([token])

      expect(token.annotations["part_of_speech_counts"]["JJ"]).to eq(6)
      expect(token.part_of_speech).to eq("JJ")
    end
  end

  context "determiner" do
    it "works" do
      token = Token.new(value: "the")
      token.add_context("The world can wait.")
      token.add_context("The world is yours.")
      token.add_context("You're the most beautiful sausage in the world.")

      PartOfSpeechAnnotation.exact_matches([token])
      expect(token.part_of_speech).to eq("DT")
    end
  end

  context "personal pronoun" do
    it "works" do
      token = Token.new(value: "my")
      token.add_context("my bologna has a first name.")
      token.add_context("my goodness, you're enormous!")

      PartOfSpeechAnnotation.exact_matches([token])
      expect(token.annotations["part_of_speech_counts"]).to eq("PRP$" => 200)
    end

    it "does not overwrite other annotations" do
      token = Token.new(value: "my")
      token.annotations["frequency"] = 100
      PartOfSpeechAnnotation.exact_matches([token])
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
      expect(token.annotations["part_of_speech_counts"]).to eq("NN" => 3)
    end
  end
end
