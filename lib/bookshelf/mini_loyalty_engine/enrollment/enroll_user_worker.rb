module MiniLoyaltyEngine
  module Enrollment
    class EnrollUserWorker
      include Sidekiq::Worker
      prepend Airflow::Job

      def initialize(
        raw_accounts_repo: RawAccountsRepository.new,
        point_accounts_repo: PointAccountsRepository.new,
        user_repo: UserRepository.new
      )
        @raw_accounts_repo = raw_accounts_repo
        @point_accounts_repo = point_accounts_repo
        @user_repo = user_repo
      end

      def perform
        register_users(unregistered_bank_account_ids)
        register_point_accounts(unregistered_point_accounts)
      end

      private

      # The difference between given today bank_account_ids and registered bank_accounts_ids
      def unregistered_bank_account_ids
        bank_account_ids = @raw_accounts_repo.today_all_bank_account_ids
        registered_bank_account_ids = @user_repo.all_registered_bank_accounts
        bank_account_ids - registered_bank_account_ids
      end

      def unregistered_point_accounts
        @user_repo.fetch_all_unregistered_point_accounts
      end

      # Given bank_accounts to register a user
      def register_users(bank_account_ids)
        return unless bank_account_ids.any?

        unregistered_users = @raw_accounts_repo.fetch_users(bank_account_ids)
        @user_repo.create_many(unregistered_users)
      end

      # Register a point account with default point balance
      def register_point_accounts(user_ids)
        return unless user_ids.any?

        default_point_acccounts = []
        user_ids.each do |user_id|
          default_point_acccounts << { user_id: user_id, point_balance: 0 }
        end

        @point_accounts_repo.create_many(default_point_acccounts)
      end
    end
  end
end
