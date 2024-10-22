class Ckeditor::PicturesController < Ckeditor::ApplicationController
  skip_before_action :verify_authenticity_token, only: :create # FIXME: this should go away


  def get_path(folder, folders)    

    if folder
      parent = folders.find_by(:id => folder.parent_id)
      path = get_path(parent, folders)

      return path + [folder]
    else
      return []
    end

  end

  def index
    # @pictures = Ckeditor.picture_adapter.find_all(ckeditor_pictures_scope)
    # @pictures = Ckeditor::Paginatable.new(@pictures).page(params[:page])

    # respond_with(@pictures, :layout => @pictures.first_page?)


    my_scope = ckeditor_pictures_scope
    my_scope.delete :order
    @pictures = Ckeditor::Picture.where(my_scope)

    if !params[:search].blank?
      pictures = Ckeditor::Picture.arel_table
      @pictures = @pictures.where(pictures[:data_file_name].matches("%#{params[:search]}%"))
    end

    @folders = Ckeditor::Folder.where(my_scope)

    @folders = @folders.where(picture_folder: true)

    @current_folder = Ckeditor::Folder.where(picture_folder: true).where(my_scope).find_by( id: params[:folder_id])
    @current_path = nil

    if @current_folder
      @current_path = get_path(@current_folder, @folders)

      @folders = @folders.where(:parent_id => @current_folder.id)
      @pictures = @pictures.where(:ckeditor_folder_id => @current_folder.id)

    else
      @folders = @folders.where(:parent_id => nil)

      @pictures = @pictures.where(:ckeditor_folder_id => nil)
    end

    # # if params[:folder_id]
    #   @folders = @folders.where(:parent_id => params[:folder_id])
    # end

    @folders = @folders.order('name ASC')

    @pictures = @pictures.order('id DESC').paginate(:page => params[:page], :per_page => 71) #71 # 98 # 80

    respond_to do |format|
      format.html { render :layout => true }
    end
  end

  def create
    @picture = Ckeditor.picture_model.new


    my_scope = ckeditor_pictures_scope
    my_scope.delete :order

    @current_folder = Ckeditor::Folder.where(picture_folder: true).where(my_scope).find_by( id: params[:ckeditor_folder_id])

    if @current_folder
      @picture.ckeditor_folder_id = @current_folder.id
    end

    respond_with_asset(@picture)
  end

  def destroy
    @picture.destroy

    respond_to do |format|
      format.html { redirect_to pictures_path }
      format.json { render :body => nil, :status => 204 }
    end
  end

  protected

    def find_asset
      @picture = Ckeditor.picture_adapter.get!(params[:id])
    end

    def authorize_resource
      model = (@picture || Ckeditor.picture_model)
      @authorization_adapter.try(:authorize, params[:action], model)
    end
end
