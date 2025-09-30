class FacultiesController < ApplicationController
  before_action :authenticate_user!

  def show
    @faculty = Faculty.find(params[:id])
    @members = @faculty.users
    @documents = Document.where(faculty_id: @faculty.id)
  end
end
