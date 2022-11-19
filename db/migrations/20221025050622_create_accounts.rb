Hanami::Model.migration do
  change do
    create_table :accounts do
      primary_key :id

      foreign_key :point_account_id, :point_accounts, type: 'uuid'

      column :bank_account_id, String, null: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end
end
