class BookCollection
  SANITIZE_CONTENT_REGEX = /[^a-zA-Z\s.!?]/

  PARTS_OF_SPEECH = {
    personal_pronoun: %w(my your their his her)
  }

  def index!
    ActiveRecord::Base.transaction do
      print "Deleting existing tokens (#{Token.count})..."
      delete_tokens
      puts

      print "Inserting new tokens (#{token_attributes.count})..."

      token_attributes.values.each_slice(1000) do |batch|
        print "."
        Token.insert_all(batch)
      end

      puts
      puts "Done"
    end
  end

  private

  def token_attributes
    return @token_attributes if @token_attributes.present?

    @token_attributes = {}

    filenames[0..1].map { |filename| File.read(filename) }
      .map { |content| Corpus.new(content[0..1000]) }
      .flat_map(&:tokenize).each do |token|
        @token_attributes[token.value] = {
          value: token.value,
          annotations: token.annotations
        }
      end

    @token_attributes
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

  def delete_tokens
    Token.find_in_batches do |tokens|
      print "."
      Token.where(id: tokens.map(&:id)).delete_all
    end
  end
end
