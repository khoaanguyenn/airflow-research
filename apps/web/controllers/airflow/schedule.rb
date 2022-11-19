require 'sidekiq/client'
require('active_support/time')

module Web
  module Controllers
    module Airflow
      # Service to push Sidkekiq::Worker to airflow queue
      class Schedule
        include Web::Action

        accept :json

        use ::Rack::Auth::Basic, 'Message' do |username, password|
          username == 'admin' && password == 'admin'
        end

        params do
          optional(:jid).value(:str?)
          optional(:retry).value(:bool?) # Retry by Sidekiq, True for using configured retry options, False for Airflow's retry
          # optional(:at).value(:float?)
          required(:queue).value(:str?)
          required(:worker_class).value(:str?)
          required(:args).value(:array?)
        end

        def initialize
          @client = ::Sidekiq::Client.new
        end

        def call(params)
          halt(400, params.error_messages) unless params.valid?

          job_params = build_job_params(params)
          jid = @client.push(**job_params)

          self.format = :json
          self.body = build_response(jid, job_params)
        end

        private

        def build_job_params(params)
          worker_class = params[:worker_class]
          job_params = {
            **worker_class.constantize.sidekiq_options,
            'jid' => params[:jid].presence,
            'class' => worker_class,
            'queue' => params[:queue],
            'args' => params[:args]
            # 'at' => params[:at]
          }.compact
          job_params.merge!('retry' => false) unless params[:retry]
          job_params
        end

        def build_response(jid, job_params)
          {
            message: 'successfully push job',
            job: {
              jid: jid,
              status: ::Sidekiq::Status.status(jid),
              queue: job_params['queue'],
              worker_class: job_params['class'],
              args: job_params['args'],
              at: job_params['at']
            }
          }.to_json
        end
      end
    end
  end
end
