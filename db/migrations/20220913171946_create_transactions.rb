Hanami::Model.migration do
  change do
    create_table :transactions do
      primary_key :id

      column :withdraw_amount, Numeric, null: false
      column :deposit_amount, Numeric, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end
end
