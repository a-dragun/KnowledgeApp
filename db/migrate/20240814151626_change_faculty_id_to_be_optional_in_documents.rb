class ChangeFacultyIdToBeOptionalInDocuments < ActiveRecord::Migration[7.1]
  def change
    change_column :documents, :faculty_id, :integer, null: true
  end
end
