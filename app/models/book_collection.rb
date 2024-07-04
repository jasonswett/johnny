class BookCollection
  def index!
    book_directory = Rails.root.join('lib', 'books')

    Dir.glob("#{book_directory}/*.txt").each do |filename|
      puts "Reading #{File.basename(filename)}..."
      content = File.read(filename).downcase.gsub(/[^a-zA-Z\s.!?]/, ' ')
    end
  end
end
