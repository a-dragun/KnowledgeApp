class AddFacultyIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :faculty_id, :integer
    add_foreign_key :users, :faculties
  end
end
