require 'sidekiq/web'
require 'sidekiq-status/web'
# Configure your routes here
# See: https://guides.hanamirb.org/routing/overview
#
# Example:
# get '/hello', to: ->(env) { [200, {}, ['Hello from Hanami!']] }
mount Sidekiq::Web, at: '/sidekiq'
Sidekiq::Web.set :session_secret, ENV.fetch('SESSIONS_SECRET')

root to: 'home#index'
post '/', to: 'books#index'
get '/books', to: 'books#index'
get '/books/new', to: 'books#new'
post '/books', to: 'books#create'
post '/testing/schedule', to: 'sidekiq#schedule'
post '/airflow/schedule', to: 'airflow#schedule'
post '/airflow/check', to: 'airflow#check'
