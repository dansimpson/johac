require 'test_helper'

class ResponseTest < JohacTest

  def test_config
    Johac.defaults { |c|
      c.base_uri = 'http://test'
      c.raise_exceptions = false
      c.auth_scheme = :basic
      c.access_key = 'test'
      c.secret_key = 'pass'
    }

    client = Johac::Client.new({
      base_uri: 'http://localhost',
      raise_exceptions: true,
      secret_key: 'pass2'
    })

    assert client.uri == 'http://localhost'
    assert client.config.raise_exceptions
    assert client.config.access_key == 'test'
    assert client.config.secret_key == 'pass2'
  end

  def test_response_error
    response = Johac::Response.new(Exception.new('what'))
    assert response.error?
    assert response.status == 0
    assert response.body == {}
  end

  def test_block_api
    Johac::Response.new(Exception.new('what'))
          .on_success { |object|
            refute true
          }
          .on_error { |err|
            assert true
            assert err.kind_of?(Exception)
          }

    Johac::Response.new(Faraday::Response.new)
          .on_success { |object|
            assert true
          }
          .on_error { |err|
            refute true
          }
  end

  def test_enumerable
    stub_johac_response(:get, '/test', 'simple')
    assert @client.test_call_get.first == ['key', 'value']
  end

  def test_enumerable_array
    stub_johac_response(:get, '/test', 'array')
    assert @client.test_call_get.first == { 'x' => 1 }
    assert @client.test_call_get.map { |v| v['x'] }.reduce(:+) == 15
  end

  def test_struct_object
    stub_johac_response(:get, '/test', 'simple')
    struct =  @client.test_call_get.object
    assert struct.key == "value"
  end

  def test_mapped_object
    stub_johac_response(:get, '/test', 'simple')
    mapped = @client.test_call_get.map_object { |hash| hash['key'] }
    assert mapped == "value"
  end

end
