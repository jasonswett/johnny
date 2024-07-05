class Corpus
  def initialize(content)
    @content = content
  end

  def tokenize
    sentences.flat_map(&:tokenize)
  end

  def sentences
    @content.split(/(?<=\.)\s+/).map do |value|
      Sentence.new(value)
    end
  end
end
