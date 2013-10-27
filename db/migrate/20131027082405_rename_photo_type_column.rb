class RenamePhotoTypeColumn < ActiveRecord::Migration
  def change
    rename_column :photos, :type, :photo_type
  end
end
