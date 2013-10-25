class ChangeUnitsToMetric < ActiveRecord::Migration
  def change
    rename_column :packages, :length_cm, :length_in
    rename_column :packages, :width_cm, :width_in
    rename_column :packages, :height_cm, :height_in
    rename_column :packages, :weight_kg, :weight_lb
  end
end
