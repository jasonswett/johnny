class BookCollection
  CONTENT_CHARACTER_LIMIT = 50000

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
    filenames.each do |filename|
      content = File.read(filename)
      Corpus.new(content[0..CONTENT_CHARACTER_LIMIT]).index(filename: File.basename(filename))
    end
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

  def filenames
    Dir.glob("#{Rails.root.join("lib", "books")}/*.txt")
  end
end
