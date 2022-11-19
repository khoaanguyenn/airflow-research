module Airflow
  module Job
    include Sidekiq::Status::Worker

    def perform(*args, **kwargs)
      @task = Task.new("sidekiq:job:#{@jid}")
      super(*args, **kwargs)
    ensure
      store(concluded?: true) if @task.concluded?
    end

    private

    def already_in_batch?
      !!@bid
    end
  end

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
        conn.publish(@channel, { status: status, details: details.to_json })
      end
    end
  end
end
