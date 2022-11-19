class RawAccountsRepository < Hanami::Repository
  associations do
    has_one :user
  end

  def create_many(data)
    command(create: :raw_accounts, result: :many).call(data)
  end

  def today_all_bank_account_ids
    today_in_utc = Time.now.utc
    raw_accounts
      .where { created_at > today_in_utc.beginning_of_day }
      .where { created_at < today_in_utc.end_of_day }
      .pluck(:bank_account_id)
  end

  def fetch_users(bank_account_ids)
    raw_accounts
      .select(:bank_account_id, :first_name, :last_name, :address, :email, :gender, :card_number, :card_type)
      .where(bank_account_id: bank_account_ids)
      .map_to(User)
      .to_a
  end
end
