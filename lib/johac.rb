$: << File.dirname(__FILE__)

require 'json'
require 'faraday'
require 'faraday_middleware'
require 'net/http/persistent'
require 'base64'
require 'ostruct'

module Johac

  class << self

    # Simple config class used to store global {Johac::Client} settings.
    #
    # @attr base_uri    [String] Hostname of Johac API.
    # @attr auth_scheme [Symbol] Authorization scheme to be used on all requests, +:basic+ or +:hmac+.
    # @attr access_key  [String] Public access key used for authorization of requests.
    # @attr secret_key  [String] Private key used for authorization of requests.
    # @attr env         [String] Environment. 'testing', 'development', or 'production'.
    Config = Struct.new(:base_uri, :auth_scheme, :access_key, :secret_key, :env, :logger, :raise_exceptions)


    # Configure the global defaults for all clients built.
    #
    # @yield [config] Passes a config object to the block.
    # @yieldparam config [Johac::Config] Config object.
    #
    # @example
    #   Johac.defaults do |config|
    #     config.base_uri = 'http://api.myservice.com'
    #     config.auth_scheme = :basic
    #     config.access_key = 'user'
    #     config.secret_key = 'password'
    #   end
    #
    # @return [Johac::Config]
    def defaults(&block)
      c = @config ||= Config.new
      c.env = environment || 'production'
      yield c
      c
    end

    # Return the config object for the global {Johac::Client} instance.
    # @return [Johac::Config]
    def config
      unless defined? @config
        raise "#{self.name} not configured. Configure via #{self.name}.configure { |cfg| ... }, or via client constructor"
      end
      @config
    end

    # Merge the new config with defaults
    def merged_config(overrides)
      case overrides
      when Hash
        dup_config.tap do |conf|
          overrides.each do |k, v|
            conf[k] = v
          end
        end
      when Struct
        dup_config.tap do |conf|
          overrides.each_pair do |k, v|
            conf[k] = v
          end
        end
      else
        config
      end
    end

    protected

    def environment
      ENV.values_at('JOHAC_ENV', 'RAILS_ENV').compact.first
    end

    private

    def dup_config
      defined?(@config) ? @config.dup : Config.new
    end

  end

end

require 'johac/version'
require 'johac/error'
require 'johac/connection'
require 'johac/response'
require 'johac/client'

