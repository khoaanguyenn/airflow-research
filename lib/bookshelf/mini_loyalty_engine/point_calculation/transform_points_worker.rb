require_relative './rules'

module MiniLoyaltyEngine
  module PointCalculation
    class TransformPointsWorker
      include Sidekiq::Worker
      prepend Airflow::Batch

      def initialize(raw_transactions_repo: RawTransactionsRepository.new, point_accounts_repo: PointAccountsRepository.new, user_repo: UserRepository.new)
        point_rules = PointRules.new(YAML.load_file(File.join(File.dirname(__FILE__), 'point_rules.yaml')))
        @point_calculator = ::PointCalculator.new(point_rules)
        @raw_transactions_repo = raw_transactions_repo
        @point_accounts_repo = point_accounts_repo
        @user_repo = user_repo
      end

      def perform
        raw_transactions = @raw_transactions_repo.all_today_transactions

        pre_point_accounts = group_by_bank_account_ids(raw_transactions).map do |bank_account_id, transactions|
          [bank_account_id, @point_calculator.calculate(transactions)]
        end

        batch_jobs do |job|
          job.add('MiniLoyaltyEngine::PointCalculation::UpdatePointWorker', pre_point_accounts)
        end
      end

      def on_complete(status, options)
        print("Heeeyyyy, I'm complete")
      end

      def on_death(status, options)
        print("Deattththhh")
      end

      private

      def group_by_bank_account_ids(transactions)
        transactions.group_by(&:bank_account_id)
      end
    end
  end
end
