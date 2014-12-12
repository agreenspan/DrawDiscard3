Rails.application.routes.draw do


  root to: 'static_pages#home'
  match 'search', to: 'search#search', via: [:get]
  match 'contact', to: 'static_pages#contact', via: [:get]
  match 'bots', to: 'static_pages#bots', via: [:get]
  match 'disabled', to: 'static_pages#disabled', via: [:get]
  match 'packs', to: 'magic_sets#packs', via: [:get]
  match 'planars', to: 'magic_sets#planars', via: [:get]
  match 'sign_in', to: 'sessions#sign_in', via: [:get, :post]
  match 'sign_out', to: 'sessions#sign_out', via: [:delete]
  match 'register', to: 'users#register', via: [:get]
  match 'reset_password', to: 'users#reset_password', via: [:get, :post]
  match 'confirmation', to: "users#confirmation", via: [:get, :post]
  match 'session_update', to: 'sessions#update', via: [:put]
  match 'transaction', to: 'transactions#transaction', via: [:post]
  match 'cancel', to: 'transactions#cancel', via: [:post]


  resources :users, only: [:create, :update] do
    get 'collection'
    get 'transactions'
    match 'change_password', to: 'users#change_password', via: [:get]
    match 'mtgo_accounts', to: 'users#mtgo_accounts', via: [:get]
    match 'mtgo_codes', to: 'users#mtgo_codes', via: [:get, :post]
  end

  resources :magic_sets, only: [:show], path: '/' do
    resources :magic_cards, only: [:show], path: '/'
  end



  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
