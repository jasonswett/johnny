require "rails_helper"

RSpec.describe Token do
  context "no contexts" do
    it "works" do
      token = Token.new(value: "my")
      token.high_certainty_parts_of_speech
      expect(token.parts_of_speech).to eq({})
    end
  end

  context "no parts of speech" do
    it "works" do
      token = Token.new(value: "my")
      allow(token).to receive(:parts_of_speech).and_return({})
      expect(token.part_of_speech).to be nil
    end
  end

  context "noun followed by article" do
    it "works" do
      token = Token.new(value: "world")
      token.add_context("The world can wait.")
      token.add_context("The world is yours.")
      token.add_context("You're the most beautiful sausage in the world.")

      token.nouns
      expect(token.parts_of_speech).to eq(noun: 3)
    end
  end

  context "end" do
    it "works" do
      token = Token.new(value: "big")
      token.add_context("I pet the big")

      token.adjectives({})
      expect(token.parts_of_speech).to eq({})
    end
  end

  context "adjective" do
    let!(:tokens) do
      {
        "the" => Token.create!(
          value: "the",
          annotations: { part_of_speech: "article" }
        ),
        "a" => Token.create!(
          value: "a",
          annotations: { part_of_speech: "article" }
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

      token.adjectives(tokens)
      expect(token.parts_of_speech[:adjective]).to eq(3)
    end
  end

  context "article" do
    it "works" do
      token = Token.new(value: "the")
      token.add_context("The world can wait.")
      token.add_context("The world is yours.")
      token.add_context("You're the most beautiful sausage in the world.")

      token.high_certainty_parts_of_speech
      expect(token.part_of_speech).to eq("article")
    end
  end

  context "personal pronoun" do
    it "works" do
      token = Token.new(value: "my")
      token.add_context("my bologna has a first name.")
      token.add_context("my goodness, you're enormous!")

      token.high_certainty_parts_of_speech
      expect(token.parts_of_speech).to eq(personal_pronoun: 2)
    end

    it "does not overwrite other annotations" do
      token = Token.new(value: "my")
      token.annotations["frequency"] = 100
      token.high_certainty_parts_of_speech
      expect(token.annotations["frequency"]).to eq(100)
    end
  end

  context "noun" do
    it "works" do
      token = Token.new(value: "truck")
      token.add_context("my truck is blue.")
      token.add_context("get out of my truck.")
      token.add_context("your truck is okay")

      token.nouns
      expect(token.parts_of_speech).to eq(noun: 3)
    end
  end

  describe "determination" do
    it "goes with the most common one" do
      token = Token.new(value: "fly")

      allow(token).to receive(:parts_of_speech).and_return(
        noun: 10,
        verb: 30
      )

      expect(token.part_of_speech).to eq("verb")
    end
  end
end
