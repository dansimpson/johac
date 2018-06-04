module Johac

  # Provides {#connection}.
  #
  # Uses the {https://github.com/lostisland/faraday faraday} lib to handle HTTP requests.
  #
  # @see https://github.com/lostisland/faraday
  module Connection

    private

    def connection
      @connection ||= Faraday.new(:url => uri) do |faraday|
        faraday.use :johac_connection_exceptions

        faraday.request :json
        faraday.request :johac_headers
        faraday.request :johac_auth, @config.auth_scheme, @config.access_key, @config.secret_key

        # Allow caller to tap into the request before it is sent
        if @config.request_tap
          faraday.request :request_tap, @config.request_tap
        end

        # Retry requests
        faraday.request :retry, {
          max: 2,
          interval: 0.5,
          backoff_factor: 3,
          interval_randomness: 0.5,

          # All connection errors + 429, 503, and 504
          exceptions: [
            Johac::Error::ConnectionError,
            Johac::Error::RetryableError
          ]
        }

        # apparently the response middleware acts like a stack, not a queue
        faraday.response :json

        # Raise connection errors as exceptions
        faraday.response :johac_raise_error

        faraday.adapter :johac_persistent do |http|
          # http param is an instance of Net::HTTP::Persistent
          #
          http.open_timeout = 2
          http.read_timeout = 60
          http.idle_timeout = 120

          # http.keep_alive
          # http.max_requests
          # http.socket_options
          http.debug_output = STDOUT if env == 'development'
        end
      end
    end

  end

  # Custom middleware.
  module Connection::Middleware

    # Wrapper of {Faraday::Adapter::NetHttpPersistent} adapter that allows for
    # a block to be given when the faraday connection is created. Block is
    # passed the newly created {Net::HTTP::Persistent} instance to be modified
    # if desired.
    #
    # Allows for configuration of HTTP connection.
    #
    # @see https://github.com/lostisland/faraday
    # @see https://github.com/drbrain/net-http-persistent
    class PersistentAdapter < Faraday::Adapter::NetHttpPersistent

      Faraday::Adapter.register_middleware :johac_persistent => self

      # Extend Faraday::Adapter::NetHttpPersistent's initialize method with an
      # optional block.
      #
      # @yield [Net::HTTP::Persistent] Stores the passed block for use when
      #   creating a new HTTP connection.
      def initialize(app, &block)
        @config_block = block
        super(app)
      end

      # Yield HTTP connection to supplied block.
      def with_net_http_connection(env, &block)
        http = super(env) { |v| v }
        @config_block.call(http) if @config_block
        yield http
      end

    end

    # Write custom user agent to all requests.
    class JohacHeaders < Faraday::Middleware

      Faraday::Request.register_middleware :johac_headers => self

      AgentString = "johac/#{Johac::Version} ruby/#{RUBY_VERSION}".freeze
      Accept      = 'application/json'.freeze

      def call(env)
        env[:request_headers]['User-Agent'] = AgentString
        env[:request_headers]['Accept'] = Accept
        env[:request_headers]['Content-Type'] = Accept
        @app.call(env)
      end

    end

    # Write custom user agent to all requests.
    class RequestTapMiddleware < Faraday::Middleware

      Faraday::Request.register_middleware :request_tap => self

      def initialize(app, request_tap)
        @request_tap = request_tap
        super(app)
      end

      def call(env)
        @request_tap.call(env)
        @app.call(env)
      end

    end

    # Adds Authorization header to all requests.
    class Authorization < Faraday::Middleware

      Faraday::Request.register_middleware :johac_auth => self

      def initialize(app, scheme, access_key, secret_key)
        @scheme = scheme
        @access_key = access_key
        @secret_key = secret_key
        super(app)
      end

      def call(env)
        if auth = case @scheme
                  when :basic then "Basic #{basic_auth_token}"
                  when :hmac  then "hmac #{hmac_auth_token(env.url.path)}"
                  end
          env[:request_headers]['Authorization'] = auth
        end
        @app.call(env)
      end

      private

      def basic_auth_token
        Base64.strict_encode64("#{@access_key}:#{@secret_key}")
      end

      # TODO: Need a hook for generating the value
      def hmac_auth_token(token)
        OpenSSL::HMAC.hexdigest('sha1', @secret_key, token)
      end

    end

    # Will raise some {Johac::Error::ResponseError} from an HTTP response using status codes.
    class RaiseError < Faraday::Response::Middleware

      Faraday::Response.register_middleware :johac_raise_error => self

      def on_complete(env)
        if e = ::Johac::Error::ResponseError.from_response(env.status, env.response_headers, env.body)
          raise e
        end
      end

    end

    # Will raise some {Johac::Error::ConnectionError} if something happens with the connection.
    class Exceptions < Faraday::Middleware

      Faraday::Middleware.register_middleware :johac_connection_exceptions => self

      def call(env)
        @app.call(env)
      rescue Faraday::Error::ConnectionFailed => e
        raise ::Johac::Error::ConnectionError, e.message
      rescue Faraday::Error::ResourceNotFound => e
        raise ::Johac::Error::ConnectionError, e.message
      rescue Faraday::Error::ParsingError => e
        raise ::Johac::Error::ConnectionError, e.message
      rescue Faraday::Error::TimeoutError => e
        raise ::Johac::Error::ConnectionError, e.message
      rescue Faraday::Error::SSLError => e
        raise ::Johac::Error::ConnectionError, e.message
      rescue Faraday::Error::ClientError => e
        raise ::Johac::Error::ConnectionError, e.message
      rescue Faraday::Error => e
        raise ::Johac::Error::ConnectionError, e.message
      rescue Net::HTTP::Persistent::Error => e
        raise ::Johac::Error::ConnectionError, e.message, e.backtrace
      end

    end

  end

end
