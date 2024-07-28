require "rails_helper"

RSpec.describe PartOfSpeechTag do
  it "works" do
    parts_of_speech = {
      RB: %w(very quickly slowly)
    }

    PartOfSpeechTag.tag_exact_matches(parts_of_speech)

    expect(Token.f("very").parts_of_speech).to include("RB")
  end
end
