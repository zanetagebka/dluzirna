class CreateDebts < ActiveRecord::Migration[8.0]
  def change
    create_table :debts do |t|
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :due_date, null: false
      t.string :customer_email, null: false
      t.text :description
      t.string :token, null: false
      t.integer :status, default: 0, null: false  # pending: 0, notified: 1, viewed: 2, registered: 3, resolved: 4
      t.references :customer_user, null: true, foreign_key: { to_table: :users }
      t.datetime :notified_at
      t.datetime :viewed_at

      t.timestamps
    end

    # Performance indexes
    add_index :debts, :customer_email
    add_index :debts, :status
    add_index :debts, :due_date
    add_index :debts, :token, unique: true
    add_index :debts, [ :customer_email, :status ]
  end
end
