class WorkspaceController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user
  before_action :set_default_folder

  def new
    @folder = Folder.new
    @document = Document.new
    @folders = Folder.ordered_folders.select { |folder| folder.accessible_by?(current_user) }
    @documents = fetch_accessible_documents
  end

  def create
    if params[:folder_submit]
      create_folder
    elsif params[:document_submit]
      create_document
    else
      redirect_to new_workspace_path, alert: 'Invalid submission.'
    end
  end

  def delete_folder
    @folder = Folder.find_by(id: params[:folder][:id])
    
    if @folder.nil? || !@folder.accessible_by?(current_user)
      redirect_to new_workspace_path, alert: "You don't have permission to delete this folder."
    elsif @folder.is_root? || (@folder.level == 1 && @folder.faculty.present?)
      redirect_to new_workspace_path, alert: "This folder cannot be deleted."
    elsif @folder.destroy
      redirect_to new_workspace_path, notice: 'Folder deleted successfully.'
    else
      redirect_to new_workspace_path, alert: "Failed to delete the folder."
    end
  end

  private

  def authorize_user
    unless current_user.admin? || current_user.faculty_member?
      redirect_to root_path, alert: 'You are not authorized to access this page.'
    end
  end

  def folder_params
    params.require(:folder).permit(:name, :parent_id)
  end

  def document_params
    params.require(:document).permit(:title, :markdown_file, :markdown_file_content, :folder_id)
  end

  def create_folder
    @folder = Folder.new(folder_params)
    
    if current_user.admin?
      if @folder.parent_id.present?
        parent_folder = Folder.find_by(id: @folder.parent_id)
        if parent_folder.nil? || !parent_folder.accessible_by?(current_user)
          @folder.errors.add(:parent_id, "Invalid parent folder")
          @folders = accessible_folders
          render :new and return
        end
  
        @folder.parent_folder = parent_folder
        @folder.level = parent_folder.level + 1
        current_folder = parent_folder
        while current_folder
          if current_folder.faculty.present?
            @folder.faculty = current_folder.faculty
            break
          end
          current_folder = current_folder.parent_folder
        end
      else
        @folder.level = 0
      end
    else
      @folder.faculty = current_user.faculty
      if @folder.parent_id.present?
        parent_folder = Folder.find_by(id: @folder.parent_id)
        if parent_folder.nil? || !parent_folder.accessible_by?(current_user)
          @folder.errors.add(:parent_id, "Invalid parent folder")
          @folders = accessible_folders
          render :new and return
        end
        @folder.parent_folder = parent_folder
        @folder.level = parent_folder.level + 1
      else
        @folder.level = 0
      end
    end
  
    if @folder.save
      redirect_to new_workspace_path, notice: 'Folder created successfully.'
    else
      Rails.logger.debug("Folder creation failed: #{@folder.errors.full_messages}")
      @folders = accessible_folders
      render :new
    end
  end
  
  
  def create_document
    @document = Document.new(document_params.except(:file, :markdown_content))
    @document.user = current_user
    if current_user.admin?
      @document.faculty_id = find_faculty_id(@document.folder_id)
    else
      @document.faculty_id = current_user.faculty_id
    end
  
    if @document.folder_id.nil? || !accessible_folders.pluck(:id).include?(@document.folder_id)
      @document.errors.add(:folder_id, "Select a valid folder")
      @folders = accessible_folders
      render :new and return
    end
  
    if params[:document][:file].present?
      file = params[:document][:file]
      if file.content_type == 'application/pdf'
        markdown_content = convert_pdf_to_markdown(file.tempfile.path)
      elsif file.content_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        markdown_content = convert_docx_to_markdown(file.tempfile.path)
      elsif file.content_type == 'text/markdown'
        markdown_content = file.read
      elsif file.content_type == 'text/plain'
        markdown_content = file.read
      else
        @document.errors.add(:file, "Unsupported file type. Only TXT, PDF, DOCX, and Markdown files are accepted.")
        @folders = accessible_folders
        render :new and return
      end
  
      @document.markdown_file.attach(
        io: StringIO.new(markdown_content),
        filename: "#{@document.title.parameterize}.md",
        content_type: "text/markdown"
      )
    elsif params[:document][:markdown_content].present?
      @document.markdown_file.attach(
        io: StringIO.new(params[:document][:markdown_content]),
        filename: "#{@document.title.parameterize}.md",
        content_type: "text/markdown"
      )
    end
  
    if @document.save
      redirect_to new_workspace_path, notice: 'Document uploaded successfully.'
    else
      Rails.logger.debug("Document upload failed: #{@document.errors.full_messages}")
      @folders = accessible_folders
      render :new
    end
  end
  

  def accessible_folders
    if current_user.admin?
      Folder.all
    else
      Folder.where(faculty_id: current_user.faculty_id).or(Folder.where(faculty_id: nil))
    end
  end

  def fetch_accessible_documents
    accessible_folder_ids = @folders.pluck(:id)
    Document.where(folder_id: accessible_folder_ids)
  end
  
  

  def set_default_folder
    @default_folder = default_folder_for_user
  end

  def default_folder_for_user
    return Folder.root_folder if current_user.admin?
    current_user.faculty.folders.find_by(name: current_user.faculty.name)
  end

  def convert_pdf_to_markdown(pdf_path)
    require 'pdf-reader'

    reader = PDF::Reader.new(pdf_path)
    markdown_text = ""

    reader.pages.each do |page|
      page.text.each_line do |line|
        markdown_text << process_line(line)
      end
    end

    markdown_text
  end

  def convert_docx_to_markdown(docx_path)
    require 'docx'

    doc = Docx::Document.open(docx_path)
    markdown_text = ""

    doc.paragraphs.each do |para|
      markdown_text << para.text + "\n\n"
    end

    markdown_text
  end

  def process_line(line)
    processed_line = line.strip
    return "" if processed_line.match?(/^\d+$/)
    processed_line + "\n"
  end

  def find_faculty_id(folder_id)
    folder = Folder.find_by(id: folder_id)
    while folder
      return folder.faculty_id if folder.faculty_id
      folder = folder.parent_folder
    end
    nil
  end
  
end