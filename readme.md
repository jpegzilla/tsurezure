# tsurezure [![gem version](https://badge.fury.io/rb/tsurezure.svg)](https://badge.fury.io/rb/tsurezure)

this is a simple web server framework written in ruby. mainly made as a way for me to quickly put together rest apis in my favorite language.

it can be used in a very similar manner to the javascript framework express.

* * *

## usage

### installing (from rubygems)

just run `gem install tsurezure` and you'll have whatever the latest version is that I've put up.

### installing (from source):

requires:

-   ruby
-   nodejs + nodemon (**only** for hot reloading server in development mode, not necessarily required)

after cloning this repo, from the root project directory, just run `rake start` to start in production mode, or `rake dev` to run in development mode, which adds hot reloading with nodemon. gem dependencies will install automatically.

to build the gem: run `gem build tsurezure.gemspec`. then, install using `gem install tsurezure-version-number`. `version-number` is whatever version is installed based on the `.gemspec` file.

### commands

-   `rake install` will install dependencies
-   `rake check_deps` will install dependencies if not installed
-   `rake start` will run the server in production mode
-   `rake dev` will run the server in development mode
-   `rake dev_silent` will run the server in development mode with no logs
-   `rake build` will build a `.gem` file based on `tsurezure.gemspec`

### actually using tsurezure:

as for how to use tsurezure, here's a simple script to get started:

```ruby
require 'tsurezure'

# create an instance of tsurezure
server = Tsurezure.new 8888

# url: http://localhost:8888

# create an endpoint
server.register 'get', '/user/:id', lambda { |req|
  url_vars = req[:vars] # { "id" => "1" }
  params = req[:params] # {}

  # create a respsonse for the endpoint
  {
    status: 200,
    message: {
      message: "hello user ##{url_vars['id']}!"
    }.to_json
  }
}, content_type: 'application/json' # options hash

# throw in some middleware
server.add_middleware '/user/:id', lambda { |req|
  url_vars = req[:vars]

  # show a different response based on the request itself.
  # if you return from middleware, the return value will
  # be sent as the final response.
  if req[:vars]['id'] == '1'
    return {
      status: 200, message: {
      message: "hey user #1! you're the first one here!"
    }.to_json
  }

  end
}, content_type: 'application/json'

#listen for connections
server.listen
```

after you run this file, open up your browser or whatever and go to `http://localhost:8888/user/1`. you should see a json response that looks like this:

```json
{
    "message": "hey user #1! you're the first one here!"
}
```

by the way, any url parameters you pass in will be parsed as a hash inside `req[:params]`. so if you make a request like `GET http://localhost:8888/user/1?hello=world`, you'll be able to access those params inside your registration function. example:

```ruby
server.register 'get', '/user/:id', lambda { |req|
  params = req[:params] # { 'hello' => 'world' }
}, content_type: 'application/json'
```

the `listen` method can be called with no arguments to just start the server. you can also pass in a lambda or proc that will run when the server has started. the only argument that will be passed to that proc is a hash called `server_opts`. it contains some information about the current configuration:

```ruby
{
  port, # port that tsurezure is running on
  endpoints, # endpoints object containing the endpoints you've added
  middleware # middleware object containing the middleware you've added
}
```

simple example of usage:

```ruby
server.listen lambda { |opts|
  puts "listening on port #{opts[:port]}!"
}
```

the registration function for creating endpoints is very simple:

```ruby
register http_method, path, callback, options
```

`http_method` is the method to access the endpoint with. `path` is just the url.

`path` can be a path that contains variables (such as `/user/:id`). see the example above to see how it works.

`callback` is a lambda that contains the logic used to send a response. it will recieve one argument: the request that was sent to that endpoint. whatever is returned from the proc will be sent as the response from that endpoint.

`options` is a hash containing various options to somehow modify the response. valid options:

-   `content_type (default: text/plain)` - determines the mime type of the response
-   `location` - if a location header is required (301, etc), this is used to provide it.
-   `method` - if an allow header is required (405), this is used to provide it.

for middleware, it's much the same:

```ruby
add_middleware path, callback, options
```

`path` can be a path that contains variables. used in the same way as the `path` for endpoints.

`callback` is a lambda that you can use to intercept and pre-process responses. if you return from a callback in middleware, then that return value will be sent as the final response.

`options` for middleware are the same as the `options` for endpoints.

**anything** returned from a middleware will be interpreted as you trying to send a modified response. and of course, ruby will interpret the last reached statement in a method as an implicit return. to avoid this, if you want to have a middleware that doesn't necessarily send a response, just use a `return` at the end of your method to return `nil`.

* * *

## todo

-   [ ]  I'm wondering if I should change the implementation of the middleware functionality. currently, the middleware has no idea where the request it's processing is about to go. I'm thinking it may be a good idea to pass in the request's determined `responder` function which is determined before middleware is called (see `tsurezure.rb:135-160`). this will allow users to choose whether to call the final responder function. I don't know if this would be better or just different.

-   [ ]  make it so registered uris can only be accessed with the specified method, and everything else returns a 405 (maybe make this an option??)

-   [ ]  give the user an option to add middleware specifically for catching errors

## misc

disclaimer: I don't know ruby, and this is my first time using it to make something.

the name comes from yukueshirezutsurezure, one of my favorite bands. tsurezure is pronounced 'tsɯ-ɾe-dzɯ-ɾe.'
