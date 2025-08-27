Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  RouteTranslator.config do |config|
    config.force_locale = false
    config.generate_unlocalized_routes = true
    config.generate_unnamed_unlocalized_routes = false
    config.locale_param_key = :locale
  end

  localized do
    root 'homepage#index'
    get 'test' => 'homepage#test'
    
    resources :pohledavky, controller: 'public_debts', only: [:show], param: :token
    
    devise_for :users, path: 'uzivatele', path_names: {
      sign_in: 'prihlaseni',
      sign_out: 'odhlaseni', 
      sign_up: 'registrace',
      password: 'heslo',
      confirmation: 'potvrzeni',
      unlock: 'odemceni'
    }, controllers: {
      registrations: 'users/registrations'
    }
    
    namespace :admin do
      root 'dashboard#index'
      resources :debts, path: 'pohledavky' do
        member do
          patch :send_notification
        end
      end
    end
    
    namespace :customer, path: 'zakaznik' do
      resources :debts, only: [:index, :show], path: 'pohledavky'
    end
  end
  
  get '/', to: redirect('/cs')
end
