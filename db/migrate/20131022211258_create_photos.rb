class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.belongs_to :package

      t.string :type
      t.string :file_type
      t.string :description

      t.timestamps
    end
  end
end
