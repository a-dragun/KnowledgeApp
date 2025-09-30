class Faculty < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :folders, dependent: :destroy

  validates :name, presence: true

  after_create :create_faculty_folder

  private

  def create_faculty_folder
    root_folder = Folder.root_folder
    Folder.create!(name: name, parent_folder: root_folder, faculty: self)
  end
end