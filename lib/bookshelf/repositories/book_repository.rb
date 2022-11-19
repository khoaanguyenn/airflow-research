class BookRepository < Hanami::Repository
  def create_many(data)
    command(create: :books, result: :many).(data)
  end
end
