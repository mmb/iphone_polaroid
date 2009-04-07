Gem::Specification.new do |s|
  s.name     = 'iphone_polaroid'
  s.version  = '0.0.3'
  s.date     = '2009-04-05'
  s.summary  = 'Make iPhone camera pictures look like Polaroids'
  s.email    = 'matthewm@boedicker.org'
  s.homepage = 'http://github.com/mmb/iphone_polaroid'
  s.description = 'Post-process iPhone camera pictures with Polaroid effect adding date and location from EXIF.'
  s.has_rdoc = false
  s.authors  = ['Matthew M. Boedicker']
  s.files    = [
    'lib/iphone_polaroid.rb',
    'README.textile',
    'iphone_polaroid.gemspec',
    ]
  s.add_dependency('exifr', ['> 0.0.0'])
  s.add_dependency('json', ['> 0.0.0'])
  s.add_dependency('rmagick', ['> 0.0.0'])
end
