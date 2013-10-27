class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :charge_id
      t.integer :preauth_charge_cents
      t.integer :final_charge_cents
      t.belongs_to :package, index: true
    end

    remove_column :packages, :transaction_id, :integer
  end
end
