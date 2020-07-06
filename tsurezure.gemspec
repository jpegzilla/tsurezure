Gem::Specification.new do |s|
  s.name        = 'tsurezure'
  s.version     = '0.0.0'
  s.date        = '2020-05-28'
  s.summary     = 'tsurezure is a simple web server framework.'
  s.description = 'a simple ruby web server framework. like a ball of loose yarn...'
  s.authors     = ['jpegzilla']
  s.email       = 'eris@jpegzilla.com'
  s.files       = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.md', 'nodemon.json']
  s.homepage    = 'https://github.com/jpegzilla/tsurezure'
  s.license     = 'MIT'
  s.add_runtime_dependency 'json', '>= 1.8.3'
  s.add_development_dependency 'pry', '~> 0.13.1'
  s.add_development_dependency 'rspec', '~> 3.9'
end