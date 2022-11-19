class UserRepository < Hanami::Repository
  associations do
    has_one :raw_accounts
    has_one :point_accounts
  end

  def fetch_user(bank_account_id)
    aggregate(:point_accounts)
      .users
      .where(bank_account_id: bank_account_id)
      .one
  end

  def create_many(data)
    command(create: :users, result: :many).call(data)
  end

  def all_registered_bank_accounts
    users.pluck(:bank_account_id)
  end

  def fetch_all_unregistered_point_accounts
    existing_point_accounts = users.join(:point_accounts).pluck(:id)
    users.where { id.not(existing_point_accounts) }.pluck(:id)
  end
end
