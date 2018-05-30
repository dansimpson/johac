module Johac

  # {Johac} exception overrides.
  #
  # Rescue {Johac::Error Johac::Error} to catch all Johac errors.
  class Error < StandardError

    # Exception to be used when dealing with HTTP responses from a Johac API.
    class ResponseError < Error

      attr_reader :code
      attr_reader :body

      # Will attempt to decode a response body via JSON, and look for the 'message' key in the resulting (assumed) hash. If response body cannot be parsed via JSON the entire response body is set as the message for the exception.
      #
      # @param body [String] Response body.
      # @param headers [Hash] Response headers.
      def initialize(code, body, headers)
        @code = code
        @body = if headers['Content-Type'] == 'application/json'
          JSON.parse(body) rescue body
        else
          body
        end
        super(body)
      end

      # If a problem is detected in an HTTP response, build the proper exception, otherwise return nil.
      #
      # @param status_code [Integer] HTTP response code.
      # @param body [String] Response body.
      # @param headers [Hash] Response headers.
      #
      # @return [Johac::Error::RetryableError] A client or server error which may be retried
      # @return [Johac::Error::ClientError] The client has made a mistake and should take corrective action.
      # @return [Johac::Error::ServerError] If there was a problem server-side, we're on it.
      # @return [nil] If no error was detected in the response.
      def self.from_response(status_code, headers, body)
        if klass =  case status_code
                    when 429 then RetryableError
                    when 503 then RetryableError
                    when 504 then RetryableError
                    when 400..499 then ClientError
                    when 500..599 then ServerError
                    end
          klass.new(status_code, body, headers)
        end
      end

    end

    # An error that we should retry
    class RetryableError        < ResponseError; end

    # There was a problem on our side, we're working on it.
    class ServerError           < ResponseError; end

    # There was a problem with the requested or submitted resource.
    class ClientError           < ResponseError; end

    # Error specific to the http connection.
    class ConnectionError       < Error; end

  end

end
