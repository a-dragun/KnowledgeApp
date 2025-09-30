class Document < ApplicationRecord
  belongs_to :faculty, optional: true 
  belongs_to :user
  belongs_to :folder

  has_one_attached :markdown_file

  validates :title, presence: true
  validates :faculty, presence: true, unless: -> { user.admin? }
  validate :title_format

  after_save :process_markdown_file, if: -> { markdown_file.attached? }

  def accessible_by?(user)
    user.admin? || (user.faculty_member? && user.faculty_id == faculty_id)
  end

  private

  def process_markdown_file
    if markdown_file.attached?
      begin
        file_content = markdown_file.download
      rescue ActiveStorage::FileNotFoundError => e
        Rails.logger.error("File not found: #{e.message}")
      end
    end
  end

  def title_format
    if title.blank?
      errors.add(:title, "can't be blank")
    elsif title.match?(/\A\d/)
      errors.add(:title, "can't start with a number")
    elsif title.split.size > 1
      errors.add(:title, "must be a single word")
    end
  end
end
