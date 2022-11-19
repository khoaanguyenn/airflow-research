class RawTransactionsRepository < Hanami::Repository
  def create_many(data)
    command(create: :raw_transactions, result: :many).call(data)
  end

  def all_today_transactions
    today_in_utc = Time.now
    raw_transactions
      .where { created_at > today_in_utc.beginning_of_day }
      .where { created_at < today_in_utc.end_of_day }
      .map_to(RawTransactions)
      .to_a
  end
end
