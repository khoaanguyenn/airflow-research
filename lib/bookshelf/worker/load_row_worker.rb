module Bookshelf
  class LoadRowWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def initialize
      @transaction_repo = TransactionRepository.new
    end

    def perform(row)
      @transaction_repo.create(to_record(row))
    end

    private

    def to_record(row)
      row.transform_keys(&:to_sym)
    end
  end
end
