class BookCollection
  def index!
    ActiveRecord::Base.transaction do
      print "Deleting existing tokens (#{Token.count})..."
      delete_tokens
      puts

      puts "Inserting new tokens (#{token_items.keys.count})..."
      Token.insert_all(tokens)

      puts "Done"
    end
  end

  private

  def tokens
    token_items.values.map do |token_item|
      {
        value: token_item[:value],
        annotations: { frequency: token_item[:frequency] }
      }
    end
  end

  def token_items
    return @token_items if @token_items.present?

    @token_items = {}

    filenames.map { |filename| File.read(filename) }
      .map { |content| content.downcase.gsub(/[^a-zA-Z\s.!?]/, ' ') }
      .map do |sanitized_content|
        sanitized_content.scan(/\w+|[[:punct:]]/).map do |value|
          @token_items[value] ||= { value: value }

          @token_items[value][:frequency] ||= 0
          @token_items[value][:frequency] += 1
        end
      end

    @token_items
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
