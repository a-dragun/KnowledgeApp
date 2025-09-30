module Admin
  class FacultiesController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin

    def index
      @faculties = Faculty.all
    end

    def new
      @faculty = Faculty.new
    end

    def create
      @faculty = Faculty.new(faculty_params)

      if Faculty.exists?(name: @faculty.name)
        flash[:alert] = "A faculty with this name already exists."
        render :new and return
      end

      Rails.logger.info("Creating faculty with params: #{faculty_params.inspect}")
      if @faculty.save
        redirect_to admin_faculties_path, notice: 'Faculty created successfully.'
      else
        Rails.logger.error("Failed to create faculty: #{@faculty.errors.full_messages.to_sentence}")
        render :new
      end
    end

    def destroy
      @faculty = Faculty.find_by(id: params[:id])

      if @faculty.nil?
        redirect_to admin_faculties_path, alert: "Faculty not found."
      elsif delete_faculty_and_associations(@faculty)
        redirect_to root_path, notice: 'Faculty and all associated data were successfully deleted.'
      else
        redirect_to admin_faculties_path, alert: 'Failed to delete faculty. Please try again.'
      end
    end

    private

    def authorize_admin
      redirect_to root_path, alert: 'You are not authorized to access this page.' unless current_user.admin?
    end

    def faculty_params
      params.require(:faculty).permit(:name)
    end

    def delete_faculty_and_associations(faculty)
      ActiveRecord::Base.transaction do
        faculty.folders.includes(:documents).each do |folder|
          folder.documents.destroy_all
        end
        faculty.folders.each do |folder|
          delete_subfolders_and_folders(folder)
        end
        faculty.destroy!
      end
    rescue StandardError => e
      Rails.logger.error("Failed to delete faculty and associated records: #{e.message}")
      false
    end
    

    def delete_subfolders_and_folders(folder)
      folder.documents.destroy_all
      folder.subfolders.each do |subfolder|
        delete_subfolders_and_folders(subfolder)
      end
      folder.destroy!
    end
    
  end
end
