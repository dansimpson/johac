## Johac - JSON Over HTTP API Client

![build status](https://travis-ci.org/dansimpson/johac.svg?branch=master "Build Status")

Opinionated HTTP client which provides good defaults for your API Client.  Defaults:

* Requests/Responses are JSON
* Retry up to 2 times on connection errors, and HTTP errors (429, 503, 504)
* Simple backoff on retries
* Configurable exception handling (raise or return)


### Configuring Defaults

```rb
Johac.defaults do |config|
  config.env = 'development'

  # Determine if connection errors, and HTTP errors should raise an exception
  # or return a Johac::Response wrapping the exception
  config.raise_exceptions = false
  config.base_uri = 'https://api.myservice.com'
end
```


### Building an API Client

```rb
class MyAPIClient < Johac::Client

  def initialize(uri)
    super({
      base_uri: uri,
      raise_exceptions: false
    })
  end

  # Returns a Johac::Response which wraps the response, or exception
  def my_api_call(myparam)
    get("/path", {
      query: {
        param: myparam
      }
    })
  end

end

client = MyAPIClient.new('https://api.service.com')
```

### Working with Responses

The Response class wraps a faraday response or exception, and provides methods
for checking status, handling the exception, response, etc.


```rb
response = client.my_api_call('param')

# was there a networking issue, or HTTP status code >=400 ?
response.error?

# Access the underlying exception
response.exception

# Access the body of the response, or error response (json)
response.body

# http status or 0 if no response
response.status
response.code
```

Helpers

```rb
# helper to dig the response content, only if hash and success
response.dig('item', 'attribute')

# Map the body object to a domain model, or nil if error?
response.map { |hash| MyModel.new(hash) }

response.map_error { |exception| false }

# Get an ostruct for the body (empty struct if missing)
response.object
```

### Capturing Requests

Johac has some helpers to capture requests and emit faraday Env structs or curl commands

```rb
client.capture { |client|
  client.my_api_call({ foo: 'bar' })
}.each { |env|
  puts env.inspect # Faraday::Env
}

client.capture_curl { |client|
  client.my_api_call({ foo: 'bar' })
}.each { |curl|
  puts curl # curl -s -XMETHOD -H'..' 'uri...' [-d '{ ... }']
}
```

### The Endpoints Pattern

I sometimes like to organize calls into logical namespaces, then include them
in the main client API.  Here is a simple example.

```rb
module ModelOneEndpoints

  def get_ones
    get("/api/ones")
  end

end

module ModelTwoEndpoints

  def get_twos
    get("/api/twos")
  end

end

class MyClient < Johac::Client

  include ModelOneEndpoints
  include ModelTwoEndpoints

  def initialize(options)
    super(options)
  end

end

client = MyClient.new({})
client.get_twos.error?
```
