require "rails_helper"

RSpec.describe Token do
  it "works" do
    token = Token.new(value: "my")
    token.add_context("my bologna has a first name.")
    token.add_context("my goodness, you're enormous!")

    expect(token.parts_of_speech).to eq(personal_pronoun: 2)
  end
end
