require "rails_helper"

RSpec.describe Token do
  context "personal pronoun" do
    it "works" do
      token = Token.new(value: "my")
      token.add_context("my bologna has a first name.")
      token.add_context("my goodness, you're enormous!")

      expect(token.parts_of_speech).to eq(personal_pronoun: 2)
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
end
