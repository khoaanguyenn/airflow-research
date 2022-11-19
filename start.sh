redis-server --port 6379 &
echo '\033[1;31mRedis online\033[1;31m'

bundle exec sidekiq -e development -r ./config/boot.rb -C ./config/sidekiq.yml &
echo '\033[1;35mSidekiq online\033[1;35m'

bundle exec hanami server &
echo '\033[1;32mHanami server online\033[1;32m'