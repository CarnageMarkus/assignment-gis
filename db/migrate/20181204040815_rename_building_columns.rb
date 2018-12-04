class RenameBuildingColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :buildings, :"roof:shape", :roof_shape
    rename_column :buildings, :"building:max_level", :building_max_level
    rename_column :buildings, :"building:min_level", :building_min_level
    rename_column :buildings, :"building:height", :building_height
    rename_column :buildings, :"building:levels", :building_levels
    rename_column :buildings, :"type", :type_
  end
end
