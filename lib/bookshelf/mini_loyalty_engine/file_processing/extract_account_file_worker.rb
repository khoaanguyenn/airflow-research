require_relative '../../repositories/raw_accounts_repository'

module MiniLoyaltyEngine
  module FileProcessing
    # Extract out the account file from SFTP
    class ExtractAccountFileWorker
      include Sidekiq::Worker

      def initialize(file_handler: SftpHandler.new, raw_accounts_repo: RawAccountsRepository.new)
        @file_handler = FileHandler.new(handler: file_handler)
        @raw_accounts_repo = raw_accounts_repo
      end

      def perform(remote_path)
        file_path = @file_handler.download(remote_path)
        rows = read_file(file_path)
        @raw_accounts_repo.create_many(build_raw_accounts(rows))
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

      def build_raw_accounts(rows)
        header = rows.first.map(&:to_sym)
        raw_accounts = rows[1..]

        raw_accounts.map do |raw_account|
          build_single_raw_account(header, raw_account)
        end
      end

      def build_single_raw_account(header, raw_account)
        header.zip(raw_account).to_h
      end
    end
  end
end
