class Corpus
  def initialize(content)
    @content = content
  end

  def tokens
    sentences.flat_map(&:tokens)
  end

  def sentences
    @content.split(Sentence::REGEX_PATTERN).map do |value|
      Sentence.new(value)
    end
  end
end
