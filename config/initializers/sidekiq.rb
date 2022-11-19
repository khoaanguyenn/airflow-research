require('sidekiq')
require('sidekiq-status')
require('active_support/time')

module Sidekiq
  module Status
    module Storage
      protected

      def store_for_id(id, status_updates, expiration = nil, redis_pool=nil)
        status = status_updates[:status]
        concluded_job = read_field_for_id(id, :concluded?)
        redis_connection(redis_pool) do |conn|
          conn.multi do
            conn.hmset  key(id), 'update_time', Time.now.to_i, *(status_updates.to_a.flatten(1))
            conn.expire key(id), (expiration || Sidekiq::Status::DEFAULT_EXPIRY)
            # Push to channel if job hasn't concluded yet
            conn.publish "sidekiq:job:#{id}", { status: status, details: {} }.to_json if status && !concluded_job
          end[0]
        end
      end
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes
  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
end
