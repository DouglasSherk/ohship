class AddDistinctIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :distinct_id, :string
  end
end
