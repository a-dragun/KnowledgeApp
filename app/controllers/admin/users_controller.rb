class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin

  def new
    @user = User.new
  end


  def index
    @users = fetch_users
    @users = apply_filters(@users)
    @users = apply_search(@users)
    @users = apply_sort(@users)
  end

  def create
    @user = User.new(user_params)
    Rails.logger.debug("User Params: #{user_params.inspect}")
  
    if @user.save
      redirect_to @user, notice: 'User was successfully created.'
    else
      Rails.logger.debug("User Save Failed: #{@user.errors.full_messages}")
      render :new
    end
  end


  private

  def user_params
    params.require(:user).permit(:email, :name, :role, :faculty_id, :password, :password_confirmation)
  end

  def fetch_users
    User.all
  end

  def apply_filters(users)
    if params[:role].present?
      users = users.where(role: params[:role])
    end
    if params[:faculty_id].present?
      users = users.where(faculty_id: params[:faculty_id])
    end
    users
  end

  def apply_search(users)
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      users = users.where('LOWER(email) LIKE ? OR LOWER(name) LIKE ?', search_term, search_term)
    end
    users
  end

  def apply_sort(users)
    sort_column = params[:sort_column] || 'created_at'
    sort_direction = params[:sort_direction] || 'desc'
    users.order("#{sort_column} #{sort_direction}")
  end

  def authorize_admin
    redirect_to root_path, alert: 'You are not authorized to access this page.' unless current_user.admin?
  end
end
