module Sidekiq
  module Status
    module Monkeypatch
      def greeting
        puts "Hello world!"
      end

      protected

      def store_for_id(id, status_updates, expiration = nil, redis_pool=nil)
        puts "Hello i'm running"
      end
    end
  end
end

Sidekiq::Status::Storage.prepend Sidekiq::Status::Monkeypatch
