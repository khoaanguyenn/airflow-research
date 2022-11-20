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
      set_job = yield(SetJob.new)

      @batch = Sidekiq::Batch.new
      Sidekiq.redis { |conn| conn.publish("sidekiq:batch:#{@jid}", Message.new(bid: batch.bid)) }

      BATCH_STATES.each do |state|
        callback_class = instance_variable_get("@#{state}_class").presence || self.class
        callback_params = instance_variable_get("@#{state}_params").presence || {}
        @batch.on(state.to_sym, callback_class, callback_params.merge(jid: @jid))
      end

      @batch.jobs do
        set_job.each_job do |job|
          Sidekiq::Client.push_bulk(**build_bulk_params(job.class_name, job.args_array))
        end
      end
    end

    private

    def build_bulk_params(worker_class, worker_args_array)
      {
        **worker_class.constantize.sidekiq_options,
        'class' => worker_class.constantize,
        'args' => worker_args_array,
        'at' => (Time.now + 5.seconds).to_f
      }.compact
    end

    class SetJob
      attr_reader :jobs_bulk

      JobBulk = Struct.new(:class_name, :args_array)

      def initialize
        @jobs = []
      end

      def add(sub_job_class, sub_job_params)
        @jobs.append(JobBulk.new(sub_job_class, sub_job_params))
        self
      end

      def each_job(&block)
        @jobs.each { |job_bulk| block.call(job_bulk) }
      end
    end
  end
end
