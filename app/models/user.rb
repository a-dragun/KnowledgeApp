class User < ApplicationRecord
  enum role: { regular_user: 0, faculty_member: 1, admin: 2 }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :faculty, optional: true
  has_many :documents

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, allow_blank: true
  validates :password_confirmation, presence: true, if: -> { password.present? }
  validate :faculty_member_must_have_faculty
  validate :non_faculty_members_cannot_have_faculty

  def can_manage?(document)
    admin? || (faculty_member? && document.faculty_id == faculty_id)
  end

  private

  def faculty_member_must_have_faculty
    if role == 'faculty_member' && faculty_id.blank?
      errors.add(:faculty_id, "must be assigned for faculty members.")
    end
  end

  def non_faculty_members_cannot_have_faculty
    if role != 'faculty_member' && faculty_id.present?
      errors.add(:faculty_id, "can only be assigned to faculty members.")
    end
  end
end
