module Airflow
  class Message
    attr_reader :status, :details, :bid

    def initialize(status: '', details: {}, bid: '')
      @status = status
      @details = details
      @bid = bid
    end

    def to_json(*_args)
      JSON.generate(
        {
          status: @status,
          details: @details,
          bid: @bid
        }
      )
    end
    alias to_s to_json
  end
end
