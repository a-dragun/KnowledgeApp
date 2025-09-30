class AddFolderIdToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :folder_id, :integer
  end
end
