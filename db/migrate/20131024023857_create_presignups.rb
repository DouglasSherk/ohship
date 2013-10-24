class CreatePresignups < ActiveRecord::Migration
  def change
    create_table :presignups do |t|
      t.string :email
    end
  end
end
