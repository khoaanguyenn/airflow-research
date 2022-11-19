require_relative '../repositories/book_repository'

module Bookshelf
  # Add a new book to database
  class AddManyBooksWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def initialize(book_repo: BookRepository.new)
      @book_repo = book_repo
      @redis = Redis.new(url: ENV['REDIS_URL'])
    end

    def perform
      raw_data = @redis.get('books')
      return unless raw_data

      books = process_data(JSON.parse(raw_data))
      # @book_repo.create_many(books)

      batch = Sidekiq::Batch.new
      store(bid: batch.bid) # This is so weird...

      batch.jobs do
        books.each { |book| Bookshelf::AddBookWorker.perform_async(book[:title], book[:author]) }
      end
    end

    private

    def process_data(data)
      books = data[1..]
      books.map { |title, author| { title: title, author: author } }
    end
  end
end
