require 'test_helper'

class ResponseTest < JohacTest

  def setup
    create_client(true)
  end

  def test_get
    stub_johac_response(:get, '/test', 'simple')
    response = @client.test_call_get
    assert response.status == 200
    assert response.dig('nested', 'key') == 'nested'
    assert response.dig('key') == 'value'
    assert response.dig('meh') == nil
  end

  def test_head
    stub_johac_response(:head, '/test', 'simple')
    response = @client.test_call_head
    assert response.status == 200
  end

  def test_delete
    stub_johac_response(:delete, '/test', 'simple')
    response = @client.test_call_delete
    assert response.status == 200
  end

  def test_post
    stub_johac_response(:post, '/test', 'simple')
    response = @client.test_call_post
    assert response.status == 200
    assert_requested(:post, 'http://api.testhost.test/test', times: 1) { |req|
      req.body == { param: 'value' }.to_json
    }
  end

  def test_put
    stub_johac_response(:put, '/test', 'simple')
    response = @client.test_call_put
    assert response.status == 200
    assert_requested(:put, 'http://api.testhost.test/test', times: 1) { |req|
      req.body == { param: 'value' }.to_json
    }
  end

  def test_400
    stub_johac_error(:get, '/test', 400)
    assert_raises Johac::Error::ClientError do
      @client.test_call_get
    end
  end

  def test_400_response
    create_client(false)
    stub_johac_response(:get, '/test', 'simple', 400)
    response = @client.test_call_get
    assert response.status == 400
    assert response.dig('nested', 'key') == 'nested'
    assert response.dig('key') == 'value'
    assert response.dig('meh') == nil
  end

  def test_timeout
    stub_johac_timeout(:get, '/test')
    assert_raises Johac::Error::ConnectionError do
      @client.test_call_get
    end
  end


  def test_timeout_response
    create_client(false)
    stub_johac_timeout(:get, '/test')
    response = @client.test_call_get
    assert response.error?
    assert response.code == 0
    assert response.body == {}
  end

  def test_503
    stub = stub_johac_error(:get, '/test', 503)
    assert_raises Johac::Error::RetryableError do
      @client.test_call_get
    end
    assert_requested stub, :times => 3
  end

  def test_503_response
    create_client(false)
    stub = stub_johac_error(:get, '/test', 503)
    response = @client.test_call_get
    assert response.error?
    assert_requested stub, :times => 3
  end

end
