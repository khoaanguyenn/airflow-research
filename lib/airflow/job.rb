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
end
