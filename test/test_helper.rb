require 'bundler/setup'
require 'minitest/autorun'
require 'webmock/minitest'
require 'johac'

# Simple test client for tests
class TestClient < Johac::Client

  def test_call_get
    get('/test')
  end

  def test_call_get_param(params)
    get('/test', {
      query: params
    })
  end

  def test_call_head
    head('/test')
  end

  def test_call_delete
    delete('/test')
  end

  def test_call_post
    post('/test', { body: { param: 'value' } })
  end

  def test_call_put
    put('/test', { body: { param: 'value' } })
  end

  def test_call_patch
    put('/test', { body: { param: 'value' } })
  end

end


class JohacTest < MiniTest::Unit::TestCase

  def create_client(raise_exceptions=true)
    Johac.defaults { |config|
      config.env = 'development'
      config.raise_exceptions = raise_exceptions
    }

    @client = TestClient.new({
      base_uri:     'http://api.testhost.test',
      auth_scheme:  :basic,
      access_key:   'user',
      secret_key:   'password',
    })
  end


  def hash_body(name)
    JSON.parse(json_body(name))
  end

  def json_body(name)
    File.open(File.dirname(__FILE__) + "/data/#{name}.json").read
  end

  def stub_johac_response(method, path, name, code=200)
    body = hash_body(name)
    stub_request(method, "http://api.testhost.test#{path}")
      .with(basic_auth: ['user', 'password'])
      .to_return(
        :status => code,
        :body => body.to_json,
        :headers => { 'Content-Type' => 'application/json'}
      )
  end

  def stub_johac_error(method, path, code)
    stub_request(method, "http://api.testhost.test#{path}")
      .with(basic_auth: ['user', 'password'])
      .to_return(
        :status => code,
        :body => { code: code, message: 'message' }.to_json,
        :headers => { 'Content-Type' => 'application/json'}
      )
  end

  def stub_johac_timeout(method, path)
    stub_request(method, "http://api.testhost.test#{path}")
      .with(basic_auth: ['user', 'password'])
      .to_timeout
  end

end
