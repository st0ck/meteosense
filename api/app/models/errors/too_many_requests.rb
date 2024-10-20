module Errors
  class TooManyRequests < StandardError
    attr_reader :retry_after

    def initialize(retry_after: 1)
      @retry_after = retry_after
      super("Too many requests, retry after #{retry_after} seconds")
    end
  end
end
