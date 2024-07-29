require "rails_helper"

RSpec.describe Sentence do
  it "must contain a space" do
    sentence = Sentence.new(value: "www.")
    expect(sentence).not_to be_valid
  end

  it "gets stripped" do
    sentence = Sentence.new(value: "    This sentence sucks.  ")
    expect(sentence.value).to eq("this sentence sucks.")
  end

  it "strips multiple spaces in a row" do
    sentence = Sentence.new(value: "This  gets stripped.")
    expect(sentence.value).to eq("this gets stripped.")
  end

  it "strips certain characters" do
    sentence = Sentence.new(value: '\'"“”*-_')
    expect(sentence.value).to eq("")
  end

  it "does not error for duplicates" do
    Sentence.create(value: "yes sir.")
    sentence = Sentence.create(value: "yes sir.")

    expect { sentence.save }.not_to raise_error
  end
end
