require 'test_helper'

class ResponseTest < JohacTest

  def setup
    create_client(true)
  end

  def test_capture
    stub = stub_johac_response(:get, '/test', 'array')
    result = @client.capture { |client|
      client.test_call_get
    }
    assert_requested stub, :times => 0
    assert_equal 1, result.size
    assert result.first.kind_of?(Faraday::Env)
  end

  def test_capture_teardown
    stub = stub_johac_response(:get, '/test', 'array')
    result = @client.capture { |client|
      client.test_call_get
    }
    @client.test_call_get
    assert_requested stub, :times => 1
    assert_equal 1, result.size
    assert result.first.kind_of?(Faraday::Env)
  end

  def test_capture_multi
    result = @client.capture { |client|
      client.test_call_get
      client.test_call_delete
    }
    assert_equal 2, result.size
    assert_equal :get, result.first.method
    assert_equal :delete, result.last.method
  end

  def test_curl_capture
    result = @client.curl_capture { |client|
      client.test_call_get_param(key: 'value')
      client.test_call_post
    }
    assert_equal "curl -s -XGET -H'Accept: application/json' -H'Content-Type: application/json' -H'Authorization: Basic dXNlcjpwYXNzd29yZA==' 'http://api.testhost.test/test?key=value'", result.first
    assert_equal "curl -s -XPOST -H'Content-Type: application/json' -H'Accept: application/json' -H'Authorization: Basic dXNlcjpwYXNzd29yZA==' 'http://api.testhost.test/test' -d '{\"param\":\"value\"}'", result.last
  end

end
