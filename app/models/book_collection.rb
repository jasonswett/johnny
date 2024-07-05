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

      #print "Inserting new tokens (#{tokens.count})..."
      print "Inserting"

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
          annotations: {
            frequency: nil
          }
        }
      end

    @token_attributes
  end

  def old_tokens
    token_items.values.map do |token_item|
      {
        value: token_item[:value],
        annotations: {
          frequency: token_item[:frequency],
          part_of_speech: part_of_speech(token_item[:value]),
          contexts: token_item[:contexts]
        }
      }
    end
  end

  def token_items
    return @token_items if @token_items.present?

    @token_items = {}

    filenames[0..1].map { |filename| File.read(filename) }
      .map { |content| content.downcase.gsub(SANITIZE_CONTENT_REGEX, " ") }
      .map { |sanitized_content| sanitized_content.scan(/\w+|[[:punct:]]/) }
      .map { |sanitized_content_as_array| tokenize(sanitized_content_as_array) }
    @token_items
  end

  def tokenize(values)
    values.each_with_index do |value, index|
      @token_items[value] ||= {
        value: value,
        frequency: 0,
        contexts: []
      }

      @token_items[value][:frequency] += 1

      unless @token_items[value][:contexts].count >= 100
        @token_items[value][:contexts] << context(values, index)
      end
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

  def delete_tokens
    Token.find_in_batches do |tokens|
      print "."
      Token.where(id: tokens.map(&:id)).delete_all
    end
  end
end
