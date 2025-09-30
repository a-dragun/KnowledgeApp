class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:edit, :update, :destroy]

  def edit
    if current_user.admin? && current_user == @user
      redirect_to root_path, alert: 'Admins cannot edit their own profile.'
    end
  end

  def show
    @document_count = @user.documents.count
    @documents = @user.documents
  end

  def update
    filtered_params = user_params
  
    if current_user.admin?
      if filtered_params[:role] == 'faculty_member'
        filtered_params[:faculty_id] ||= @user.faculty_id
      else
        filtered_params[:faculty_id] = nil
      end
    else
      filtered_params[:role] = @user.role if filtered_params[:role].blank?
      filtered_params[:faculty_id] = @user.faculty_id if filtered_params[:faculty_id].blank?
    end
  
    if @user.update(filtered_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render :edit
    end
  end
  

  def destroy
    if current_user.admin?
      if @user == current_user
        redirect_to root_path, alert: 'Admins cannot delete their own accounts.'
      else
        @user.documents.update_all(user_id: current_user.id)
        
        @user.destroy
        redirect_to root_path, notice: 'User and their documents were successfully deleted.'
      end
    elsif current_user == @user
      @user.destroy
      redirect_to root_path, notice: 'Your account was successfully deleted.'
    else
      redirect_to root_path, alert: 'You are not authorized to delete this account.'
    end
  end
  

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :name, :role, :faculty_id)
  end

  def authorize_user
    if current_user.admin?
      return if current_user != @user
    elsif current_user != @user
      redirect_to @user, alert: 'You are not authorized to edit or delete this user.'
    end
  end
end
