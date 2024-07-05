class BookCollection
  def index!
    values = {}
    total_counts = {}

    Dir.glob("#{Rails.root.join("lib", "books")}/*.txt").each do |filename|
      puts "Reading #{File.basename(filename)}..."
      content = File.read(filename).downcase.gsub(/[^a-zA-Z\s.!?]/, ' ')

      content.scan(/\w+|[[:punct:]]/).map do |value|
        values[value] ||= value

        total_counts[value] ||= 0
        total_counts[value] += 1
      end
    end

    puts

    ActiveRecord::Base.transaction do
      print "Deleting existing tokens (#{Token.count})..."
      delete_tokens

      puts
      puts "Inserting new tokens (#{values.keys.count})..."

      tokens = values.keys.map do |value|
        {
          value: value,
          annotations: { frequency: total_counts[value] }.to_json
        }
      end

      Token.insert_all(tokens)
    end
  end

  def delete_tokens
    Token.find_in_batches do |tokens|
      print "."
      Token.where(id: tokens.map(&:id)).delete_all
    end
  end
end
