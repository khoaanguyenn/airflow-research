require 'json'

module Web
  module Controllers
    module Airflow
      class Check
        include Web::Action
        accept :json

        use ::Rack::Auth::Basic, 'Message' do |username, password|
          username == 'admin' && password == 'admin'
        end

        params do
          required(:jid).value(:str?)
        end

        def call(params)
          halt(400, params.error_messages) unless params.valid?

          # bids = JSON.parse(::Sidekiq::Status::get(jid, :bids).to_s)
          # statuses = bids.map do |bid|
          #   Sidekiq::Batch::Status.new(bid).failures != 0
          # end

          jid = params[:jid]
          self.format = :json

          worker_status = ::Sidekiq::Status.status(jid)
          batch_status = bid_status(jid)
          status = combine_status(worker_status, batch_status)

          bid = ::Sidekiq::Status::get(jid, :bid)

          self.body = {
            job: {
              jid: jid,
              status: status,
              batch: {
                bid: bid,
                status: batch_status,
                failure_info: failure_info(jid)
              },
              retry: ::Sidekiq::Status::get(jid, :retry_attempt)
            }
          }.to_json
        end

        private

        def failure_info(jid)
          bid = ::Sidekiq::Status::get(jid, :bid)
          return unless bid

          ::Sidekiq::Batch::Status.new(bid).failure_info.map(&:to_h)
        end

        def bid_status(jid)
          bid = ::Sidekiq::Status::get(jid, :bid)
          return unless bid

          status = ::Sidekiq::Batch::Status.new(bid)

          return :failed if failure?(status)
          return :working if working?(status)
          return :complete if !failure?(status) && !working?(status)
        end

        def combine_status(job_status, batch_status)
          return job_status unless batch_status
          return :failed if batch_status == :failed
          return job_status if [:complete].include?(batch_status)
          return batch_status
        end

        def failure?(status)
          status.failures == status.total
        end

        def working?(status)
          status.pending.positive?
        end
      end
    end
  end
end
