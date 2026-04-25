class Ckeditor::AttachmentFilesController < Ckeditor::ApplicationController
  skip_before_action :verify_authenticity_token, only: :create # FIXME: this should go away


  def index
    @folders_feature = ckeditor_folders_enabled

    my_scope = ckeditor_attachment_files_scope
    my_scope.delete :order
    @files = Ckeditor::AttachmentFile.where(my_scope)

    if !params[:search].blank?
      pictures = Ckeditor::AttachmentFile.arel_table
      @files = @files.where(pictures[:data_file_name].matches("%#{params[:search]}%"))
    end

    @folders = Ckeditor::Folder.where(my_scope)

    @folders = @folders.where(picture_folder: false)

    @all_folders = @folders

    @at_least_one_folder_exists = @all_folders.count > 0

    @current_folder = Ckeditor::Folder.where(picture_folder: false).where(my_scope).find_by( id: params[:folder_id])
    @current_path = nil

    if @current_folder
      @current_path = Ckeditor::Folder.get_path(@folders, @current_folder)

      @folders = @folders.where(:parent_id => @current_folder.id)
      @files = @files.where(:ckeditor_folder_id => @current_folder.id)

    else
      @folders = @folders.where(:parent_id => nil)

      @files = @files.where(:ckeditor_folder_id => nil)
    end

    # # if params[:folder_id]
    #   @folders = @folders.where(:parent_id => params[:folder_id])
    # end

    @folders = @folders.order('name ASC')

    @pagy_files, @files = pagy(:offset, @files.order('id DESC'), page: params[:page], limit: 71) #71 # 98 # 80

    respond_to do |format|
      format.html { render :layout => true }
    end
  end

  def create
    @file = Ckeditor.attachment_file_model.new

    my_scope = ckeditor_attachment_files_scope
    my_scope.delete :order

    @current_folder = Ckeditor::Folder.where(picture_folder: false).where(my_scope).find_by( id: params[:ckeditor_folder_id])

    if @current_folder
      @file.ckeditor_folder_id = @current_folder.id
    end

    respond_with_asset(@file)
  end

  def destroy
    @file.destroy

    respond_to do |format|
      format.html { redirect_to attachment_files_path }
      format.json { render :body => nil, :status => 204 }
    end
  end

  protected

    def find_asset
      @file = Ckeditor.attachment_file_adapter.get!(params[:id])
    end

    def authorize_resource
      model = (@file || Ckeditor.attachment_file_model)
      @authorization_adapter.try(:authorize, params[:action], model)
    end
end
