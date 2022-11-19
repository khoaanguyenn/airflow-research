require_relative '../../repositories/raw_transactions_repository'

module MiniLoyaltyEngine
  module FileProcessing
    # Extract transaction file and load to database
    class ExtractTransactionFileWorker
      include Sidekiq::Worker

      def initialize(file_handler: SftpHandler.new, raw_transactions_repo: RawTransactionsRepository.new)
        @file_handler = FileHandler.new(handler: file_handler)
        @raw_transactions_repo = raw_transactions_repo
      end

      def perform(remote_path)
        file_path = @file_handler.download(remote_path)
        rows = read_file(file_path)
        @raw_transactions_repo.create_many(build_raw_transactions(rows))
      end

      private

      def read_file(file_path)
        rows = []
        File.open(file_path) do |file|
          FastCSV.raw_parse(file) do |row|
            rows << row
          end
        end
        rows
      end

      def build_raw_transactions(rows)
        header = rows.first.map(&:to_sym)
        raw_transactions = rows[1..]

        raw_transactions.map do |raw_transaction|
          build_single_raw_transaction(header, raw_transaction)
        end
      end

      def build_single_raw_transaction(header, raw_transaction)
        header.zip(raw_transaction).to_h
      end
    end
  end
end
