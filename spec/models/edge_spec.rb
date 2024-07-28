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

  describe ".part_of_speech" do
    let!(:token1) { Token.create(value: "one") }
    let!(:token2) { Token.create(value: "two") }
    let!(:token3) { Token.create(value: "three") }
    
    let!(:pos_tag1) { PartOfSpeechTag.create(token: token2, part_of_speech: "noun") }
    let!(:pos_tag2) { PartOfSpeechTag.create(token: token3, part_of_speech: "verb") }
    
    let!(:edge1) { Edge.create(token_1: token1, token_2: token2, distance: 1) }
    let!(:edge2) { Edge.create(token_1: token1, token_2: token3, distance: 2) }

    it "returns edges with token_2 having the specified part of speech" do
      expect(Edge.part_of_speech("noun")).to include(edge1)
      expect(Edge.part_of_speech("noun")).not_to include(edge2)
    end

    it "does not return edges with token_2 having a different part of speech" do
      expect(Edge.part_of_speech("verb")).to include(edge2)
      expect(Edge.part_of_speech("verb")).not_to include(edge1)
    end
  end
end
