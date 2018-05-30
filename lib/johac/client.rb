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
