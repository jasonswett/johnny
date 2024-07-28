require "rails_helper"

RSpec.describe Edge do
  describe "edgify" do
    it "creates edges" do
      sentence = Sentence.new("here goes nothing.")

      expect { sentence.edges }.to change { Edge.count }.by(6)
    end

    it "saves a distance" do
      sentence = Sentence.new("here goes nothing.")
      sentence.edges

      edge = Edge.find_by(token_1: Token.f("here"), token_2: Token.f("nothing"))
      expect(edge.distance).to eq(2)
    end

    context "same combination twice" do
      it "saves without problems" do
        sentence = Sentence.new("one two one two")

        expect { sentence.edges }.to change { Edge.count }.by(5)
      end

      it "increments the count" do
        sentence = Sentence.new("one two one two")
        edge = sentence.edges.first
        expect(edge.reload.count).to eq(2)
      end
    end
  end
end
