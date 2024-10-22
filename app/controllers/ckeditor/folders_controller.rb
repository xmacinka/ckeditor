class Ckeditor::FoldersController < Ckeditor::ApplicationController
  skip_before_action :verify_authenticity_token, only: :create # FIXME: this should go away

  def create
    @folder = Ckeditor.folder_model.new

    @folder.name = params[:folder_name].to_s.strip

    if params[:type] == 'picture'
      @folder.picture_folder = true
    else
      @folder.picture_folder = false
    end

    @folder.type = 'Ckeditor::Folder'


    # check that parent is the correct account_id
    if params[:parent_id]
      @folder.parent_id = params[:parent_id]
    end

    if @folder.name.length > 0

      ckeditor_before_create_asset(@folder)
      @folder.save

      redirect_to params[:redirect_back_url], notice: "Folder created"
      return
    end

    redirect_to params[:redirect_back_url], error: "Folder couldn't be created"
  end

  def destroy

    my_scope = ckeditor_pictures_scope
    my_scope.delete :order

    @folders = Ckeditor::Folder.where(my_scope)

    @folder = @folders.find_by(id: params[:id])

    base_path = pictures_path

    if @folders.where(parent_id: @folder.id).count > 0
      redirect_back fallback_location: base_path, flash: {error: "Can't delete a folder containing subfolders"}
      return
    end


    @folder.destroy

    respond_to do |format|
      format.html { redirect_back fallback_location: base_path}
      format.json { render :body => nil, :status => 204 }
    end
  end

  protected


    def find_asset
      # @folder = Ckeditor.folder_adapter.get!(params[:id])
      my_scope = ckeditor_pictures_scope
      my_scope.delete :order

      @folder = Ckeditor::Folder.where(my_scope).find_by(id: params[:id])
    end

    def authorize_resource
      model = (@folder || Ckeditor.folder_model)
      @authorization_adapter.try(:authorize, params[:action], model)
    end
end
