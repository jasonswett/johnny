class BookCollection
  def index!
    values = {}

    Dir.glob("#{Rails.root.join("lib", "books")}/*.txt").each do |filename|
      puts "Reading #{File.basename(filename)}..."
      content = File.read(filename).downcase.gsub(/[^a-zA-Z\s.!?]/, ' ')

      content.scan(/\w+|[[:punct:]]/).map do |value|
        values[value] ||= value
      end
    end

    puts

    ActiveRecord::Base.transaction do
      print "Deleting existing tokens (#{Token.count})..."
      delete_tokens

      puts
      puts "Inserting new tokens (#{values.keys.count})..."
      Token.insert_all(values.keys.map { |value| { value: value } })
    end
  end

  def delete_tokens
    Token.find_in_batches do |tokens|
      print "."
      Token.where(id: tokens.map(&:id)).delete_all
    end
  end
end
