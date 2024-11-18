Ckeditor::Engine.routes.draw do
  resources :pictures, :only => [:index, :create, :destroy]
  resources :attachment_files, :only => [:index, :create, :destroy]
  resources :folders, :only => [:create, :update, :destroy] do
    match 'bulk_action', :on => :collection, :via => [:post]
  end
end
