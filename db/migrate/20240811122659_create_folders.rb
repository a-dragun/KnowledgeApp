class CreateFolders < ActiveRecord::Migration[7.1]
  def change
    create_table :folders do |t|
      t.string :name
      t.string :parent_id
      t.string :integer
      t.integer :faculty_id

      t.timestamps
    end
  end
end
