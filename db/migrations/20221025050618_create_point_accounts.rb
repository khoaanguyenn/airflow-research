Hanami::Model.migration do
  up do
    execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

    create_table :point_accounts do
      primary_key :id, 'uuid', null: false, default: Hanami::Model::Sql.function(:uuid_generate_v4)

      foreign_key :user_id, :users, type: 'uuid'

      column :point_balance, Numeric, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end

  down do
    drop_table :point_accounts
    execute 'DROP EXTENSION IF EXISTS "uuid-ossp"'
  end
end
