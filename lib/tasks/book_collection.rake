namespace :book_collection do
  task index: :environment do
    book_collection = BookCollection.new
    book_collection.index!
  end
end
