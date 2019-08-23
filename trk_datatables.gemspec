lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trk_datatables/version'

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = 'trk_datatables'
  spec.version       = TrkDatatables::VERSION
  spec.authors       = ['Dusan Orlovic']
  spec.email         = ['duleorlovic@gmail.com']

  spec.summary       = %q(Gem that simplify using datatables with Ruby on Rails and Sinatra.)
  spec.description   = %q(Html render first page, sort and filter...)
  spec.homepage      = 'https://github.com/trkin/trk_datatables'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/trkin/trk_datatables'
    spec.metadata['changelog_uri'] = 'https://github.com/trkin/trk_datatables/CHANGELOG.md'
    spec.metadata['yard.run'] = 'yri' # use "yard" to build full HTML docs.
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # for HashWithIndifferentAccess
  spec.add_dependency 'activesupport'

  spec.add_development_dependency 'activerecord', '~> 6.0'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-color'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'sqlite3'
end
# rubocop:enable Metrics/BlockLength
