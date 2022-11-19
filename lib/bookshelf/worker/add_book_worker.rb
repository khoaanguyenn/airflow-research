require_relative '../repositories/book_repository'

module Bookshelf
  # Add a new book to database
  class AddBookWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def initialize(book_repo: BookRepository.new)
      @book_repo = book_repo
    end

    def perform(title, author)
      total 100

      sleep(3)
      at 25

      raise RuntimeError.new('Booom') if [true, false].sample

      book = { title: title, author: author }
      @book_repo.create(book)

      sleep(2)
      at 100
    end
  end
end
