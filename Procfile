redis: redis-server --port 6379
web: bundle exec hanami server
worker: bundle exec sidekiq -e development -r ./config/boot.rb -C ./config/sidekiq.yml
