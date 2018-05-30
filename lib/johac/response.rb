module Johac
  class Response

    attr_reader :response
    attr_reader :exception

    include Enumerable

    def initialize(result)
      if result.kind_of?(Faraday::Response)
        @response = result
      else
        @exception = result
      end
    end

    # Determine if the request failed
    #
    # @return true if response failed (http or expcetion)
    def error?
      exception != nil || status >= 400
    end

    # HTTP Status code
    #
    # @return response status code
    def status
      response_status || exception_status || 0
    end

    # HTTP Status code
    #
    # @return response status code
    def code
      status
    end

    # HTTP Response body as a JSON parsed object
    #
    # @return Hash/Array of the JSON parsed body, or empty hash
    def body
      response_body || exception_body || {}
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
    # @see {Array.dig}
    #
    # @return value of key path
    def dig(*args)
      body.dig(*args)
    end

    # Enumerate over response body opject
    #
    # @see {Enumerable}
    # @param block [Block] to invoke
    def each(&block)
      body.each(&block)
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

    protected

    def response_status
      response? ? response.status : nil
    end

    def response_body
      response? ? response.body : nil
    end

    def exception_status
      response_error? ? exception.code : nil
    end

    def exception_body
      response_error? ? exception.body : nil
    end

    def response_error?
      exception.kind_of?(Johac::Error::ResponseError)
    end

    def response?
      response != nil
    end

  end
end
