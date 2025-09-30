class Folder < ApplicationRecord
  belongs_to :faculty, optional: true
  belongs_to :parent_folder, class_name: "Folder", foreign_key: "parent_id", optional: true
  has_many :subfolders, class_name: "Folder", foreign_key: "parent_id", dependent: :destroy
  has_many :documents, dependent: :destroy

  validates :name, presence: true
  validate :parent_folder_must_be_valid, if: :parent_id_present?
  validate :name_format

  before_save :set_level
  before_destroy :check_if_root_folder

  def accessible_by?(user)
    return true if user.admin?
    return false unless user.faculty
    faculty_folder = user.faculty.folders.find_by(name: user.faculty.name)
    return false unless faculty_folder
    faculty_folder.descendants.include?(self) || self == faculty_folder
  end

  def is_root?
    parent_id.nil?
  end

  def self.ordered_folders
    folders = []
    root_folders = Folder.where(parent_id: nil)

    root_folders.each do |root_folder|
      folders << root_folder
      fetch_subfolders(folders, root_folder.id)
    end

    folders
  end

  def descendants
    subfolders.flat_map { |subfolder| [subfolder] + subfolder.descendants }
  end

  def formatted_name
    indent = level
    "#{'—' * indent} #{name}"
  end

  def path_from_root
    return name if is_root?
  
    path = []
    current_folder = self
    while current_folder.level != 0
      path.unshift(current_folder.name)
      current_folder = current_folder.parent_folder
    end
    path.join('/')
  end

  private

  def set_level
    self.level = parent_folder ? parent_folder.level + 1 : 0
  end

  def parent_folder_must_be_valid
    if parent_id.present? && parent_folder.nil?
      errors.add(:parent_id, "must be a valid folder!")
    end
  end

  def parent_id_present?
    parent_id.present?
  end

  def check_if_root_folder
    if is_root?
      errors.add(:base, "Root and faculty folders cannot be deleted!")
      throw(:abort)
    end
  end

  def self.root_folder
    find_by(parent_id: nil)
  end

  def self.fetch_subfolders(folders, parent_id)
    subfolders = Folder.where(parent_id: parent_id)
    subfolders.each do |subfolder|
      folders << subfolder
      fetch_subfolders(folders, subfolder.id)
    end
  end

  def name_format
    if name.blank?
      errors.add(:name, "can't be blank")
    elsif name.match?(/\A\d/)
      errors.add(:name, "can't start with a number")
    elsif name.split.size > 1
      errors.add(:name, "must be a single word")
    end
  end
end
