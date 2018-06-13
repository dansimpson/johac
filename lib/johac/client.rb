module Johac

  # Base class for Johac API Client.
  #
  # Extend this class and provide API specific calls
  class Client

    attr_reader :config

    # HTTP lib inclusion
    #
    # Supplies one method, {#connection}.
    #
    # The {#connection} method should return an object that responds to HTTP verbs (eg. #get, #post, #put, #delete).
    include Connection

    # @param config [Johac::Config]
    def initialize(config=nil)
      @config = Johac.merged_config(config)
      @mutex = Mutex.new
    end

    # Reference to +base_uri+ set on {Johac.config} in {Johac.configure} or in the constructor.
    #
    # @return [String]
    def uri
      config.base_uri
    end

    # Reference to the current environment. Set explicitly in {Johac.configure} or via
    # environment variables +JOHAC_ENV+ or +RAILS_ENV+.
    #
    # @return [String] One of "testing", "development", or "production"
    def env
      config.env
    end

    # Produce curls commands for captured requests made, within the block
    #
    # @param [Block] the block which invokes one or more requests
    # @return [String] requests which were captured as curl commands
    def curl_capture(&block)
      capture(&block).map { |env|
        output = []
        output << "curl -s -X#{env.method.to_s.upcase}"
        env.request_headers.select { |name, value|
          name.downcase != 'user-agent'
        }.each { |name, value|
          output << "-H'#{name}: #{value}'"
        }
        output << "'#{env.url}'"
        if env.body
          output << '-d'
          output << "'#{env.body}'"
        end
        output.join(' ')
      }
    end

    # Capture requests and prevent them from going to the remote.  Useful
    # for testing.
    #
    # @param [Block] the block which invokes one or more requests
    # @return [Array] faraday env structs which were captured in the block
    def capture(&block)
      result = []
      @mutex.synchronize {
        begin
          connection.options.context = result
          yield(self)
        ensure
          connection.options.context = nil
        end
      }
      result
    end

    protected

    def head(path, options={})
      request { connection.head(path, options[:query], options[:headers]) }
    end

    def get(path, options={})
      request { connection.get(path, options[:query], options[:headers]) }
    end

    def delete(path, options={})
      request { connection.delete(path, options[:query], options[:headers]) }
    end

    def post(path, options={})
      request { connection.post(path, options[:body], options[:headers]) }
    end

    def put(path, options={})
      request { connection.put(path, options[:body], options[:headers]) }
    end

    def patch(path, options={})
      request { connection.patch(path, options[:body], options[:headers]) }
    end



    private

    # Wrap the response or error, or raise an exception if configured
    def request(&block)
      Johac::Response.new(yield)
    rescue => e
      @config.raise_exceptions ? (raise e) : Johac::Response.new(e)
    end

  end
end
