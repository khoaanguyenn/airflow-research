module Airflow
  module Batch
    attr_reader :batch, :details

    BATCH_STATES = %w[complete success death].freeze
    BATCH_TO_AIRFLOW_STATE = {
      'complete' => 'complete',
      'success' => 'success',
      'death' => 'failed'
    }.freeze

    BATCH_STATES.each do |state|
      define_method("set_#{state}") do |params = {}, klass = self|
        instance_variable_set("@#{state}_class", klass.class)
        instance_variable_set("@#{state}_params", params)
      end

      define_method("on_#{state}") do |status, options|
        @task = Task.new("sidekiq:batch:#{options['jid']}")
        super(status, options) if defined?(super)
        @task.mark!(BATCH_TO_AIRFLOW_STATE[state]) unless @task.concluded?
      end
    end

    def batch_jobs
      worker_class_name, worker_args_array = yield

      @batch = Sidekiq::Batch.new
      Sidekiq.redis { |conn| conn.publish("sidekiq:batch:#{@jid}", batch.bid) }

      BATCH_STATES.each do |state|
        callback_class = instance_variable_get("@#{state}_class").presence || self.class
        callback_params = instance_variable_get("@#{state}_params").presence || {}
        @batch.on(state.to_sym, callback_class, callback_params.merge(jid: @jid))
      end

      @batch.jobs do
        Sidekiq::Client.push_bulk(**build_bulk_params(worker_class_name, worker_args_array))
      end
    end

    def setup_sub_worker_array(sub_worker_array, sub_worker_params)
      [sub_worker_array, sub_worker_params]
    end

    private

    # def publish_status(status, details)
    #   publish_channel(@from_jid, { status: status, details: details })
    # end

    # def publish_channel(jid, payload)
    #   redis { |conn| conn.publish("sidekiq:batch:#{jid}", payload.to_json) }
    #   logger.info(payload)
    # end

    def build_bulk_params(worker_class, worker_args_array)
      {
        **worker_class.constantize.sidekiq_options,
        'class' => worker_class.constantize,
        'args' => worker_args_array,
        'at' => (Time.now + 5.seconds).to_f
      }.compact
    end
  end
end
