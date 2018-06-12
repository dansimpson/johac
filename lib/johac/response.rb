module Johac
  class Response

    attr_reader :response, :exception, :body, :status, :chain

    def initialize(result, chain=[])
      if result.kind_of?(Faraday::Response)
        @response = result
      else
        @exception = result
      end

      @body = result.body if result.respond_to?(:body)
      @status = result.status if result.respond_to?(:status)
      @chain = chain
    end

    # Determine if the request failed
    #
    # @return true if response failed (http or expcetion)
    def error?
      status.nil? || status >= 400
    end

    # HTTP Status code
    #
    # @return response status code
    def code
      status
    end

    # @return OpenStruct object of hash, or empty struct if error
    def object
      if error?
        OpenStruct.new(body)
      else
        OpenStruct.new
      end
    end

    # Map response body if successful
    #
    # @param block [Block] mapping function block
    #
    # @return result of block
    def map(&block)
      unless error?
        yield body
      else
        nil
      end
    end

    # Map the exception if present
    #
    # @param block [Block] to invoke
    def map_error(&block)
      if error?
        yield exception
      else
        nil
      end
    end

    # Dig for a item in the body
    #
    # @param args [Varargs] path of value
    #
    # @see {Hash.dig}
    #
    # @return value of key path
    def dig(*args)
      body.kind_of?(Hash) ? body.dig(*args) : nil
    end

    # Chain another request to the successful response.  The expected
    # output of the block is another Johac::Response object.
    #
    # This enables request chaining, where an error in the chain will
    # prevent further processing and return an error response
    #
    # response = client.request1(param)
    #                  .flat_map { |r| client.request2(r.object.value) }
    #                  .flat_map { |r| client.request3(r.object.value) }
    #
    # @param block [Block] to invoke
    def flat_map(&block)
      if response?
        begin
          result = yield self, chain
          result.set_chain(chain + [self])
          result
        rescue => e
          Response.new(e, chain + [self])
        end
      else
        self
      end
    end

    # @see flat_map
    def and_then(&block)
      flat_map(&block)
    end

    protected

    def set_chain(chain)
      @chain = chain
    end

    def response?
      response != nil
    end

  end
end
