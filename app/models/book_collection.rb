class BookCollection
  def index!
    tokens = {}

    Dir.glob("#{Rails.root.join("lib", "books")}/*.txt").each do |filename|
      puts "Reading #{File.basename(filename)}..."
      content = File.read(filename).downcase.gsub(/[^a-zA-Z\s.!?]/, ' ')

      content.scan(/\w+|[[:punct:]]/).map do |value|
        tokens[value] ||= value
      end
    end

    puts

    ActiveRecord::Base.transaction do
      puts "Destroying existing tokens..."
      Token.destroy_all

      puts "Inserting new tokens..."
      Token.insert_all(tokens.keys.map { |value| { value: value } })
    end
  end
end
