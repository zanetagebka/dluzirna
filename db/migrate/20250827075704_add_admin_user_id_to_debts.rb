class AddAdminUserIdToDebts < ActiveRecord::Migration[8.0]
  def change
    add_reference :debts, :admin_user, null: true, foreign_key: { to_table: :users }
  end
end
