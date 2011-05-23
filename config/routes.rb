CthulhuQuest::Application.routes.draw do
  namespace :facebook do
    root :to => "facebook#home"
    
    resources :items, :only => [:index]    
    
    resources :investigators, :only => [:new,:create,:show] do
      resource :gift, :only => [:create]
      resource :heal, :only => [:create,:show], :controller => 'healing', :defaults => {:kind => 'medical'}
      resource :becalm, :only => [:create,:show], :controller => 'healing', :defaults => {:kind => 'spirit'}
    end
    resource  :investigator, :only => [:edit,:destroy], :path_names => {:edit => 'profile'}
    resources :stats, :only => [:update]
    resource  :journal, :only => [:show], :controller => 'journal'
    resources :casebook, :controller => 'plot_threads', :only => [:index] do
      resources :investigations, :only => [:new,:create,:update]
    end
    resources :assignments, :only => [:update]
    resources :possessions, :only => [:update] do
      member do
        post :purchase
      end
    end    
    resources :armaments, :only => [:update] do
      member do
        post :purchase
      end
    end
    resources :monsters, :only => :none do
      resources :combats, :only => [:new,:create]
    end    
    resources :allies, :only => [:index,:destroy,:create]
    resources :contacts, :only => [:index,:show]  do
      resources :plot_threads, :only => [:create]   
      resources :introductions, :only => [:create]   
      member do
        put :entreat
      end      
    end
    resources :characters, :only => [:show]
    resources :introductions, :only => [:update,:destroy]
    resources :social_functions, :only => [:index]  do
      resources :socials, :only => [:create,:update]
    end
    resources :socials, :only => :none do
      resources :guests, :only => [:new,:create]
    end    
    resources :spellbooks, :only => [:index,:update]
    resources :spells, :only => :none do
      resources :castings, :only => [:new,:create]
    end
    resource  :location, :only => [:show,:update] do
      resources :plot_threads, :only => [:create]
      resources :taskings, :only => :none do
        resources :efforts, :only => [:create]
      end
    end
    resources :psychoses, :only => [:update,:destroy]
  end
  
  namespace :touch do
    root :to => "touch#home"
  end
  
  namespace :web do
    resource :user, :only => [:show] do
      member do
        delete :logout
      end
    end
    
    resources :items, :only => [:index] do
      collection do
        get :artifacts
      end
    end
    resources :weapons, :only => [:index]
    resources :spellbooks, :only => [:index,:update]
    resources :spells, :only => :none do
      resources :castings, :only => [:create]
    end
    
    resources :locations, :only => [:index,:show,:update]
    
    resources :monsters, :only => :none do
      resources :combats, :only => [:new,:create]
    end
    
    resources :investigators, :only => [:new,:create,:show] do
      resource :gift, :only => [:create]
      member do
        put :heal
      end        
    end
    resource  :investigator, :only => [:edit], :path_names => {:edit => 'profile'} do
      member do
        put :heal
      end
    end
    resource :journal, :only => [:show], :controller => 'journal'
    
    resources :social_functions, :only => [:index] do
      resources :socials, :only => [:create,:update] do
      end
    end
    
    resources :socials, :only => [:none] do
      resources :guests, :only => [:create]
    end
    
    resources :possessions, :only => [:destroy] do
      member do
        post :purchase
      end
    end
    resources :armaments, :only => [:update] do
      member do
        post :purchase
      end
    end
    
    resources :stats, :only => [:update]            
    resources :allies, :only => [:index,:create,:destroy]
    resources :characters, :only => [:show]
    resources :contacts, :only => [:show] do
      member do
        put :entreat
      end
      
      resources :introductions, :only => [:create]
    end
    resources :introductions, :only => [:update,:destroy]
    
    resources :assignments, :only => [:edit,:update]
    
    resources :casebook, :controller => 'plot_threads', :only => [:index,:show,:create] do
      resources :investigations, :except => [:index,:update] do
        member do
          put :complete
          put :solve
          put :hasten
        end
      end
    end
    
    match 'guide' => "web#guide", :via => :get
    match 'rules' => "web#rules", :via => :get
    match 'quickstart' => "web#quickstart", :via => :get
    match 'topsites' => "web#topsites", :via => :get
    root :to => "web#home"
  end
  
  match 'oauth/authorize' => 'authorization#authorize', :as => :oauth_authorize, :via => "get"
  match 'oauth/deauthorize' => 'authorization#deauthorize', :as => :oauth_deauthorize, :via => "get"
  match 'oauth/callback' => 'authorization#callback', :as => :oauth_callback, :via => "get"
  
  root :to => 'application#landing'
end