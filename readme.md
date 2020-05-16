# tsurezure

this is a simple web server framework written in ruby. mainly made as a way for me to quickly put together rest apis in my favorite language.

the name comes from yukueshirezutsurezure, one of my favorite bands.

it's 'tsɯ-ɾe-dzɯ-ɾe.'

## usage

### installing

requires:
-   ruby
-   nodejs (only for hot reloading server in development mode)

from the project directory, just run `rake start` to start in production mode, or `rake dev` to run in development mode, which adds some log output and hot reloading with nodemon. gem dependencies will install automatically.

# todo

make it so registered uris can only be accessed with the specified method, and everything else returns a 405

give the user an option to add middleware for catching errors, etc
