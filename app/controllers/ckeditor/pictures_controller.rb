class Ckeditor::PicturesController < Ckeditor::ApplicationController

  def index
    # @pictures = Ckeditor.picture_adapter.find_all(ckeditor_pictures_scope)
    # @pictures = Ckeditor::Paginatable.new(@pictures).page(params[:page])
    @pictures = Ckeditor.picture_adapter.find_all(ckeditor_pictures_scope)
    @pictures = @pictures.paginate(:page => params[:page], :per_page => 80) # 98 # 80

    respond_with(@pictures)
  end

  def create
    @picture = Ckeditor.picture_model.new
    respond_with_asset(@picture)
  end

  def destroy
    @picture.destroy
    respond_with(@picture, :location => pictures_path)
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
