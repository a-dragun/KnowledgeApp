class RemoveColumnFromFolders < ActiveRecord::Migration[7.1]
  def change
    remove_column :folders, :integer, :string
  end
end
