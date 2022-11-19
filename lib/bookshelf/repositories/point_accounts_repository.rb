class PointAccountsRepository < Hanami::Repository
  associations do
    has_one :user
  end

  def create_many(data)
    command(create: :point_accounts, result: :many).call(data)
  end
end
