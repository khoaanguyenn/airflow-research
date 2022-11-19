module Bookshelf
  # Fetch file from SFTP and temporary store to Redis
  class FetchSFTPFileWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    sidekiq_options retry: 3

    def initialize(sftp: SftpHandler.new)
      self.sidekiq_retry_in_block ||= _retry_block
      @file_handler = FileHandler.new(handler: sftp)
      @redis_client = Redis.new(url: ENV['REDIS_URL'])
    end

    def perform(remote_path)
      file = @file_handler.download(remote_path)
      sleep(20.seconds.to_i)
      @redis_client.setex(file_signature, 2.hours.to_i, file)
    end

    private

    def _retry_block
      proc do |count, _exception|
        store retry_attempt: count.to_s
        20
      end
    end

    def file_signature
      "#{Date.today}_transactions"
    end
  end
end
