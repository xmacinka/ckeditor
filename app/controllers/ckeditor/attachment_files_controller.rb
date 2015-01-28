class Ckeditor::AttachmentFilesController < Ckeditor::ApplicationController

  def index
    # @attachments = Ckeditor.attachment_file_adapter.find_all(ckeditor_attachment_files_scope)
    # @attachments = Ckeditor::Paginatable.new(@attachments).page(params[:page])

    # respond_with(@attachments, :layout => @attachments.first_page?)
    my_scope = ckeditor_attachment_files_scope
    my_scope.delete :order
    @attachments = Ckeditor::AttachmentFile.where(my_scope)

    if !params[:search].blank?
      attachments = Ckeditor::AttachmentFile.arel_table
      @attachments = @attachments.where(attachments[:data_file_name].matches("%#{params[:search]}%"))
    end

    respond_to do |format|
      format.html { render :layout => @attachments }
    end
  end

  def create
    @attachment = Ckeditor.attachment_file_model.new
    respond_with_asset(@attachment)
  end

  def destroy
    @attachment.destroy

    respond_to do |format|
      format.html { redirect_to attachment_files_path }
      format.json { render :nothing => true, :status => 204 }
    end
  end

  protected

    def find_asset
      @attachment = Ckeditor.attachment_file_adapter.get!(params[:id])
    end

    def authorize_resource
      model = (@attachment || Ckeditor.attachment_file_model)
      @authorization_adapter.try(:authorize, params[:action], model)
    end
end
