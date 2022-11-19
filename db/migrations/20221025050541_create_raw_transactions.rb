Hanami::Model.migration do
  up do
    execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

    create_table :raw_transactions do
      primary_key :id, 'uuid', null: false, default: Hanami::Model::Sql.function(:uuid_generate_v4)

      column :bank_account_id, String, null: false
      column :transaction_amount, Numeric, null: false
      column :transaction_type, String, null: false
      column :transaction_date, DateTime, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end
  
  down do
    drop_table :raw_transactions
    execute 'DROP EXTENSION IF EXISTS "uuid-ossp"'
  end
end
