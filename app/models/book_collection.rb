class BookCollection
  def index!
    book_directory = Rails.root.join('lib', 'books')

    Dir.glob("#{book_directory}/*.txt").each do |filename|
      puts filename
    end
  end
end
