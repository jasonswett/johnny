class Corpus
  def initialize(content)
    @content = content
  end

  def sentences
    @content.split(/(?<=\.)\s+/)
  end
end
