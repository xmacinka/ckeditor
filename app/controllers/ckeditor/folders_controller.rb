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

    parent = nil

    if params[:parent_id]
      parent = Ckeditor::Folder.find_by(id: params[:parent_id])

      if !(parent.assetable_id == ckeditor_filebrowser_scope[:assetable_id] && parent.assetable_type == ckeditor_filebrowser_scope[:assetable_type])

        redirect_to params[:redirect_back_url], notice: "Folder couldn't be created"
        return
      end

      @folder.parent_id = params[:parent_id]
    end

    if folder_with_same_name_exists?(@folder.name, @folder.picture_folder, parent)


      redirect_to params[:redirect_back_url], notice: "Folder with the same name already exists"
      return
    end

    if @folder.name.length > 0

      ckeditor_before_create_asset(@folder)
      @folder.save

      redirect_to params[:redirect_back_url], notice: "Folder created"
      return
    end

    redirect_to params[:redirect_back_url], flash: {error: "Folder couldn't be created"}
  end

  def update

    new_name = params[:new_folder_name].to_s.strip

    my_scope = ckeditor_filebrowser_scope
    my_scope.delete :order

    parent = Ckeditor::Folder.find_by(id: @folder.parent_id)

    if folder_with_same_name_exists?(new_name, @folder.picture_folder, parent)

      redirect_to params[:redirect_back_url], notice: "Folder with the same name already exists"
      return
    end

    if new_name.length > 0 && new_name != @folder.name
      @folder.name = new_name
      @folder.save

      redirect_to params[:redirect_back_url], notice: "Folder renamed"
      return
    end

    redirect_to params[:redirect_back_url], flash: {error: "Folder couldn't be renamed"}
  end

  def destroy

    my_scope = ckeditor_filebrowser_scope
    my_scope.delete :order

    @folders = Ckeditor::Folder.where(my_scope)

    @folder = @folders.find_by(id: params[:id])


    if @folder.picture_folder == true
      base_path = pictures_path
      files = Ckeditor::Picture.where(my_scope)
    else
      base_path = attachment_files_path
      files = Ckeditor::AttachmentFile.where(my_scope)
    end

    if files.where(ckeditor_folder_id: @folder.id).count > 0
      redirect_back fallback_location: base_path, flash: {error: "Can't delete a folder containing files"}
      return
    end

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

  def bulk_action

    my_scope = ckeditor_filebrowser_scope
    my_scope.delete :order


    if params[:type] == 'picture'
      base_path = pictures_path
      files = Ckeditor::Picture.where(my_scope)
    else
      base_path = attachment_files_path
      files = Ckeditor::AttachmentFile.where(my_scope)
    end

    notice = ''
    affected_files = 0


    if params[:bulk_action] == 'move'

      folders = Ckeditor::Folder.where(my_scope)
      folder = folders.find_by(id: params[:new_folder_id])

      new_folder_id = nil
      folder_name = "root directory"

      if folder
        new_folder_id = folder.id
        folder_name = folder.get_full_path(folders)
      end

      if params[:asset_ids] && params[:asset_ids].length > 0
        asset_ids = params[:asset_ids]

        asset_ids.each do |asset_id|

          asset = files.find_by(id: asset_id)

          if @authorization_adapter.try(:authorized?, "destroy", asset)
            if asset.ckeditor_folder_id != new_folder_id
              asset.ckeditor_folder_id = new_folder_id
              asset.save
              affected_files += 1
            end
          end
        end

        notice = "Moved "+affected_files.to_s+" files to "+folder_name.to_s
      end
    end


    respond_to do |format|
      format.html { redirect_back fallback_location: base_path, flash: {notice: notice}}
      format.json { render :body => nil, :status => 204 }
    end
  end


  protected


    def folder_with_same_name_exists?(name, picture_folder, parent)
      my_scope = ckeditor_filebrowser_scope
      my_scope.delete :order

      folders = Ckeditor::Folder.where(my_scope).where(picture_folder: picture_folder)
      if parent
        folders = folders.where(:parent_id => parent.id)
      else
        folders = folders.where(:parent_id => nil)        
      end

      return folders.where('name ILIKE ?', "#{name}").count > 0
    end

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
