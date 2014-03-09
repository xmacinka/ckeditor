class Ckeditor::PicturesController < Ckeditor::ApplicationController

  def index
    # @pictures = Ckeditor.picture_model.find_all(ckeditor_pictures_scope)
    my_scope = ckeditor_pictures_scope
    my_scope.delete :order
    @pictures = Ckeditor::Picture.where(my_scope)

    if !params[:search].blank?
      pictures = Ckeditor::Picture.arel_table
      @pictures = @pictures.where(pictures[:data_file_name].matches("%#{params[:search]}%"))
    end

    @pictures = @pictures.order('id DESC').paginate(:page => params[:page], :per_page => 71) #71 # 98 # 80
    respond_with(@pictures)
  end

  def create
    @picture = Ckeditor::Picture.new
	  respond_with_asset(@picture)
  end

  def destroy
    @picture.destroy
    respond_with(@picture, :location => pictures_path)
  end

  protected

    def find_asset
      @picture = Ckeditor.picture_model.get!(params[:id])
    end

    def authorize_resource
      model = (@picture || Ckeditor::Picture)
      @authorization_adapter.try(:authorize, params[:action], model)
    end
end
