Hanami::Model.migration do
  up do
    execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

    create_table :users do
      primary_key :id, 'uuid', null: false, default: Hanami::Model::Sql.function(:uuid_generate_v4)

      column :bank_account_id, String, null: false
      column :first_name, String, null: false
      column :last_name, String, null: false
      column :address, String, null: false
      column :email, String, null: false
      column :gender, String, null: false
      column :card_number, String, null: false
      column :card_type, String, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end

  down do
    drop_table :users
    execute 'DROP EXTENSION IF EXISTS "uuid-ossp"'
  end
end
