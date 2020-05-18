# tsurezure

this is a simple web server framework written in ruby. mainly made as a way for me to quickly put together rest apis in my favorite language.

it can be used in a very similar manner to the javascript framework express.

* * *

## usage

### installing (development):

requires:

-   ruby
-   nodejs + nodemon (**only** for hot reloading server in development mode)

after cloning this repo, from the root project directory, just run `rake start` to start in production mode, or `rake dev` to run in development mode, which adds some log output and hot reloading with nodemon. gem dependencies will install automatically.

### actually using tsurezure:

first, build the gem: `gem build tsurezure.gemspec`. then, install using `gem install tsurezure-version-number`. `version-number` is whatever version is installed based on the `.gemspec` file.

as for how to use tsurezure, here's a simple hello world to get started:

```ruby
# require tsurezure
require 'tsurezure'

# create an instance
server = Tsurezure.new(8888)

# create an endpoint
server.register 'get', '/', proc { |req|
  { status: 200, message: 'hello world' }
}, content_type: 'text/plain'

#listen for connections
server.listen
```

the registration function for creating endpoints is very simple:

```ruby
def register(http_method, path, responder, options = nil)
```

example based on the hello world file above:

```ruby
server.register 'get', # http_method

'/', # path

proc { |req|
  { status: 200, message: 'hello world' }
}, # responder

content_type: 'text/plain' # options
```

`http_method` is the method to access the endpoint with. `path` is just the url.

`responder` is a proc that contains the logic used to send a response. it will recieve one argument: the request that was sent to that endpoint. whatever is returned from the proc will be sent as the response from that endpoint.

`options` is a hash containing various options to somehow modify the response. for now, the only option is just to set the `content_type` response header. the default is `text/plain`.

* * *

## todo

make it so registered uris can only be accessed with the specified method, and everything else returns a 405

give the user an option to add middleware for catching errors, etc

## misc

the name comes from yukueshirezutsurezure, one of my favorite bands.

it's pronounced 'tsɯ-ɾe-dzɯ-ɾe.'
