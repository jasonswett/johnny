require "rails_helper"

RSpec.describe Token do
  describe "related_tokens" do
    it "works" do
      token = Token.create!(value: "world")
      Token.related([token])
    end
  end
end
