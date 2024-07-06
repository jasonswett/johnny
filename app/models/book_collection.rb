class BookCollection
  MAX_CONTEXT_COUNT = 10

  def index!
    print "Deleting existing tokens (#{Token.count})..."
    delete_tokens
    puts

    print "Inserting new tokens (#{token_attributes.count})..."

    token_attributes.values.each_slice(1000) do |batch|
      puts batch.first
      Token.insert_all(batch)
    end

    puts
    print "Determining parts of speech..."
    Token.all.find_each do |token|
      token.annotations["part_of_speech"] = token.part_of_speech
      token.save!
    end

    puts
    puts "Done"
  end

  private

  def token_attributes
    return @token_attributes if @token_attributes.present?

    @token_attributes = {}

    filenames[0..1].map { |filename| File.read(filename) }
      .map { |content| Corpus.new(content) }
      .flat_map(&:sentences).each do |sentence|
        sentence.tokens.each do |token|
          attrs = @token_attributes[token.value] || token.serialize

          attrs[:annotations][:frequency] ||= 0
          attrs[:annotations][:frequency] += 1

          attrs[:annotations][:contexts] ||= []

          if attrs[:annotations][:contexts].count < MAX_CONTEXT_COUNT
            attrs[:annotations][:contexts] << sentence.to_s
          end

          @token_attributes[token.value] = attrs
        end
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
