class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: [:show, :update, :destroy, :download]
  before_action :authorize_user, only: [:show, :update, :destroy]
  helper_method :can_edit_or_delete_document?

  def show
  end

  def index
    @documents = fetch_documents
    @documents = apply_filters(@documents)
    @documents = apply_search(@documents)
    @documents = apply_sort(@documents)
  end

  def update
    if params[:document][:markdown_file].present?
      @document.markdown_file.attach(params[:document][:markdown_file])
    elsif params[:document][:markdown_file_content].present?
      @document.markdown_file.attach(
        io: StringIO.new(params[:document][:markdown_file_content]),
        filename: @document.markdown_file.filename.to_s,
        content_type: 'text/markdown'
      )
    end

    if @document.update(document_params.except(:markdown_file))
      redirect_to document_path(@document), notice: 'Document was successfully updated.'
    else
      render :show
    end
  end

  def destroy
    if @document.destroy
      redirect_to new_workspace_path, notice: 'Document was successfully deleted.'
    else
      redirect_to document_path(@document), alert: 'Failed to delete the document.'
    end
  end

  def download
    if @document.markdown_file.attached?
      send_data(
        @document.markdown_file.download,
        filename: "#{@document.title.parameterize}.md",
        type: @document.markdown_file.content_type,
        disposition: 'attachment'
      )
    else
      redirect_to new_workspace_path, alert: 'File not found.'
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to new_workspace_path, alert: 'Document not found.'
  end

  def authorize_user
    return if action_name == 'show'
    return if current_user.admin?
  
    if current_user.faculty_member?
      if @document.folder.faculty_id == current_user.faculty_id
        return
      end
    end
  
    redirect_to root_path, alert: 'You are not authorized to access this document.'
  end
  

  def document_params
    params.require(:document).permit(:title, :markdown_file)
  end

  def fetch_documents
    Document.all
  end

  def apply_filters(documents)
    if params[:faculty_id].present?
      documents = documents.joins(:folder).where(folders: { faculty_id: params[:faculty_id] })
    end
  
    if params[:user_id].present?
      documents = documents.where(user_id: params[:user_id])
    end
  
    documents
  end
  

  def apply_search(documents)
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      documents = documents.joins(:user).where(
        'LOWER(documents.title) LIKE ? OR LOWER(users.name) LIKE ? OR LOWER(CAST(documents.created_at AS TEXT)) LIKE ?',
        search_term, search_term, search_term
      )
    end
    documents
  end
  

  def apply_sort(documents)
    sort_column = params[:sort_column] || 'created_at'
    sort_direction = params[:sort_direction] || 'desc'
    documents.order("#{sort_column} #{sort_direction}")
  end
  
  def can_edit_or_delete_document?
    return false if current_user.regular_user?
    return true if current_user.admin?
  
    @document.folder.faculty_id == current_user.faculty_id
  end
  
end
