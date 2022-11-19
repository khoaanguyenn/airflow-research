require_relative '../repositories/book_repository'

module Bookshelf
  # Add a new book to database
  class ListBookWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def initialize(book_repo: BookRepository.new)
      @book_repo = book_repo
    end

    def perform
      total 100

      sleep(5)
      at 25

      sleep(5)
      at 50

      sleep(5)
      at 75

      sleep(5)
      at 100

      @book_repo.all
    end
  end
end
