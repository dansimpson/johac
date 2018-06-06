module Johac
  class Response

    attr_reader :response, :exception, :body, :status

    include Enumerable

    def initialize(result)
      if result.kind_of?(Faraday::Response)
        @response = result
      else
        @exception = result
      end

      @body = result.body if result.respond_to?(:body)
      @status = result.status if result.respond_to?(:status)
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

    # @return OpenStruct object of hash
    def object
      OpenStruct.new(body)
    end

    # Map body hash to another value using a block
    #
    # @param block [Block] mapping function block
    #
    # @return result of block
    def map_object(&block)
      yield body
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

    # Enumerate over response body object and return
    # a new Response with a modified body
    #
    # @see {Enumerable}
    # @param block [Block] to invoke
    def each(&block)
      if response?
        body.each(&block)
      else
        self
      end
    end

    # Invoke a block of code if the response fails, with
    # the exception as the paramter.
    #
    # @param block [Block] to invoke
    def on_error(&block)
      if error?
        yield exception
      end
      self
    end

    # Invoke a block of code if the response succeeds, with the content
    # as a parameter
    #
    # @param block [Block] to invoke
    def on_success(&block)
      unless error?
        yield body
      end
      self
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
          yield self
        rescue => e
          Response.new(e)
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

    def response?
      response != nil
    end

  end
end
