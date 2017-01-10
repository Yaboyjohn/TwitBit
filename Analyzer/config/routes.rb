Rails.application.routes.draw do
  get 'errors/not_found'

  get 'errors/internal_server_error'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'searches/new'
  root 'searches#new'
  resources :searches
  get 'searches/words/:id', to: 'searches#words', as: "searches_words"
  match "/404", :to => "errors#not_found", :via => :all
  match "/500", :to => "errors#internal_server_error", :via => :all
end
