source 'https://rubygems.org'

gem 'rake'
gem 'hanami',       '~> 1.3'
gem 'hanami-model', '~> 1.3'
gem 'bigdecimal', '~> 1.4'

gem 'sqlite3'
gem 'pg'

gem 'redis', '~> 4.0'
gem 'sidekiq', '~> 5.1'
gem 'sidekiq-status'
gem 'activesupport', '~> 7.0', '>= 7.0.3'
gem 'net-sftp', '~> 3.0'
gem 'daru', '~> 0.3'
gem 'fastcsv'

gem 'sinatra', require: false

# Don't have credentials on docker
source "https://gems.contribsys.com/" do
  gem 'sidekiq-pro', require: ['sidekiq-pro', 'sidekiq/pro/web']
end

# gem 'sidekiq-batch'

group :development do
  # Code reloading
  # See: https://guides.hanamirb.org/projects/code-reloading
  gem 'shotgun', platforms: :ruby
  gem 'hanami-webconsole'
end

group :test, :development do
  gem 'dotenv', '~> 2.4'
end

group :test do
  gem 'rspec'
  gem 'capybara'
end

group :production do
  # gem 'puma'
end
