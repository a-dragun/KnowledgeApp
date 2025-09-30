class AddLevelToFolders < ActiveRecord::Migration[7.1]
  def change
    add_column :folders, :level, :integer
  end
end
