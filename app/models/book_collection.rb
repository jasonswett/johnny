class BookCollection

  def index!
    print "Deleting existing tokens (#{Token.count})..."
    Token.delete_all
    puts

    puts "Inserting new tokens..."
    token_attributes

    puts
    puts "Determining parts of speech..."
    PartOfSpeechAnnotation.label_parts_of_speech(Token.all)

    puts
    puts "Done"
  end

  private

  def token_attributes
    Corpus.all.map(&:index) # this has never been tested
  end

  def part_of_speech(value)
    PARTS_OF_SPEECH.each do |part_of_speech, words|
      return part_of_speech if words.include?(value)
    end

    "unknown"
  end

  def context(values, index)
    start_index = [0, index - 3].max
    end_index = [index + 3, values.size - 1].min
    values[start_index..end_index].join(" ")
  end
end
