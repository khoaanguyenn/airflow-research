module Airflow
  class Task
    attr_reader :jid, :channel, :details

    FINAL_STATES = %w[success fail].freeze

    def initialize(channel)
      @channel = channel
    end

    FINAL_STATES.each do |state|
      define_method("#{state}!") do |details = {}|
        mark!(state, details)
      end
    end

    def log(payload)
      @details = payload
    end

    # Conclude the task to be either success or failure
    def concluded?
      !!@concluded
    end

    def mark!(status, details = nil)
      details = details || @details || {}
      publish(status, details)
    end

    private

    def publish(status, details)
      @concluded = true if FINAL_STATES.include?(status)
      Sidekiq.redis do |conn|
        conn.publish(@channel, Message.new(status: status, details: details))
      end
    end
  end
end
