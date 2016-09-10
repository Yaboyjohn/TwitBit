Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'searches/new'
  root 'searches#new'
  resources :searches
end
