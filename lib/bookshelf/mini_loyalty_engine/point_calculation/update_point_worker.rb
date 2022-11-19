module MiniLoyaltyEngine
  module PointCalculation
    class UpdatePointWorker
      include Sidekiq::Worker

      sidekiq_options :retry => false

      def initialize(user_repo: UserRepository.new, point_accounts_repo: PointAccountsRepository.new)
        @user_repo = user_repo
        @point_accounts_repo = point_accounts_repo
      end

      def perform(bank_account_id, add_points)
        raise Interrupt, 'Death for sure!'
        point_account = @user_repo.fetch_user(bank_account_id).point_accounts
        updated_point = point_account.point_balance + add_points
        @point_accounts_repo.update(point_account.id, point_balance: updated_point)
      end
    end
  end
end
