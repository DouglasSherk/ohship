class CreateFeedback < ActiveRecord::Migration
  def change
    create_table :feedback do |t|
      t.belongs_to :package
      t.string :text
    end
  end
end
