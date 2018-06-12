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
    assert response.status == nil
    assert response.body == nil
  end

  def test_block_api
    response = Johac::Response.new(Exception.new('what'))
    refute response.map { |object|
      true
    }
    assert response.map_error { |err|
      true
    }

    response = Johac::Response.new(Faraday::Response.new(status: 200))
    assert response.map { |object|
      true
    }
    refute response.map_error { |err|
      true
    }
  end

  def test_enumerable
    stub_johac_response(:get, '/test', 'simple')
    assert @client.test_call_get.body.first == ['key', 'value']
  end

  def test_enumerable_array
    stub_johac_response(:get, '/test', 'array')
    assert @client.test_call_get.body.first == { 'x' => 1 }
    assert @client.test_call_get.map { |a| a.map { |v| v['x'] }}.reduce(:+) == 15
  end

  def test_struct_object
    stub_johac_response(:get, '/test', 'simple')
    struct =  @client.test_call_get.object
    assert struct.key == "value"
  end

  def test_mapped_object
    stub_johac_response(:get, '/test', 'simple')
    mapped = @client.test_call_get.map { |hash| hash['key'] }
    assert mapped == "value"
  end

  def test_monadic_mapping
    stub = stub_johac_response(:get, '/test', 'array')
    response =  @client.test_call_get
                       .flat_map { |r, chain|
                          assert_equal 0, chain.size
                          @client.test_call_get
                       }.flat_map { |r, chain|
                          assert_equal 1, chain.size
                          @client.test_call_get
                       }.flat_map { |r, chain|
                          assert_equal 2, chain.size
                          @client.test_call_get
                       }
    assert response.kind_of?(Johac::Response)
    assert response.body.count == 5
    assert_requested stub, :times => 4
  end

  def test_monadic_mapping_error
    @client.config.raise_exceptions = false
    stub = stub_johac_response(:get, '/test', 'array', 400)
    response =  @client.test_call_get
                       .flat_map { |r| @client.test_call_get }
                       .flat_map { |r| @client.test_call_get }
    assert response.kind_of?(Johac::Response)
    assert response.error?
    assert_requested stub, :times => 1
  end

  def test_request_tap
    stub_johac_response(:get, '/test', 'array')
    @client.config.request_tap = lambda { |env|
      env[:request_headers]['Tapped'] = 'Yes'
    }
    @client.test_call_get

    assert_requested :get, @client.uri + '/test',
      headers: {'Tapped' => 'Yes' },
      times: 1
  end

end
