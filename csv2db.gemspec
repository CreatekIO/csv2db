lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'csv2db/version'

Gem::Specification.new do |spec|
  spec.name          = 'csv2db'
  spec.version       = Csv2db::VERSION
  spec.authors       = ['Createk']
  spec.email         = ['dev@createk.io']
  spec.licenses      = ['MIT']

  spec.summary       = 'Imports CSVs into ActiveRecord'
  spec.homepage      = 'https://github.com/CreatekIO/csv2db'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = ''

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/CreatekIO/csv2db'
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

  spec.add_dependency 'activerecord', '>= 4.2', '< 7.1'
  spec.add_dependency 'activesupport', '>= 4.2', '< 7.1'
  spec.add_dependency 'charlock_holmes', '~> 0.7.3'
  spec.add_dependency 'dragonfly', '~> 1'
  spec.add_dependency 'railties', '>= 4.2', '< 7.1'
  spec.add_dependency 'sidekiq', '>= 3'

  spec.add_development_dependency 'bundler', '>= 2.2.18', '< 3'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'mysql2', '~> 0.5.3'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
