require "rails_helper"

RSpec.describe Token do
  context "no contexts" do
    it "works" do
      token = Token.new(value: "my")
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

  context "personal pronoun" do
    it "works" do
      token = Token.new(value: "my")
      token.add_context("my bologna has a first name.")
      token.add_context("my goodness, you're enormous!")

      expect(token.parts_of_speech).to eq(personal_pronoun: 2)
    end

    it "does not overwrite other annotations" do
      token = Token.new(
        value: "my",
        annotations: {
          frequency: 100
        }
      )

      token.parts_of_speech
      expect(token.annotations["frequency"]).to eq(100)
    end
  end

  context "noun" do
    it "works" do
      token = Token.new(value: "truck")
      token.add_context("my truck is blue.")
      token.add_context("get out of my truck.")
      token.add_context("your truck is okay")

      expect(token.parts_of_speech).to eq(noun: 3)
    end
  end

  describe "determination" do
    it "works" do
      token = Token.new(value: "fly")

      allow(token).to receive(:parts_of_speech).and_return(
        noun: 10,
        verb: 30
      )

      expect(token.part_of_speech).to eq("verb")
    end
  end
end
