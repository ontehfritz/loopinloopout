Loopinloopout::Application.routes.draw do
  resources :notifications
  resources :follows
  resources :subscriptions
  resources :sound_file_bookmarks
  resources :votes
  resources :luser_projects
  devise_for :users
  
  match ":username/banks/browse" => "banks#browse"
  match ":username/banks/bookmarked" => "banks#bookmarked"
  
  scope ":username" do
    resources :projects do 
      
      member do 
        post 'upload_file'
        get 'rules'
        get 'prizes'
      end
      
      resources :discussions
      resources :sound_file_scores
      resources :project_scores
    end
    resources :bank_bookmarks 
    resources :activities
    
    resources :banks do
      member do
        get 'copy' 
        get 'download'
      end
      resources :sound_files
    end
  end
  
  resources :lusers 
  resources :modes
  resources :sound_types
  resources :softwares
  
  get 'banks/update_subtypes', :as => 'update_subtypes'
  get 'banks/update_files', :as => 'update_files'
  get 'banks/update_subtypes', :as => 'update_subtypes'
  get 'banks/copy_to', :as => 'copy_to'
  get 'banks/copy_files', :as => 'copy_files'
  post 'sound_files/update_listen_count', :as => 'update_listen_count'
  #get 'banks/browse', :as => 'browse'

  match "explore" => "home#explore"
  match "search" => "home#search"
  match ":username" => "home#show"
  root :to => 'home#index'
end
