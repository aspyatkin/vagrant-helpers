Gem::Specification.new do |s|
  s.name = 'vagrant-helpers'
  s.version = '1.5.0'
  s.date = '2019-01-31'
  s.summary = 'Vagrant helpers'
  s.description = 'Vagrant helpers plugin'
  s.authors = ['Alexander Pyatkin']
  s.email = 'aspyatkin@gmail.com'
  s.files = ['lib/vagrant-helpers.rb']
  s.homepage = 'http://github.com/aspyatkin/vagrant-helpers'
  s.license = 'MIT'

  s.required_ruby_version = '>= 2.4'

  s.add_dependency 'dotenv', '~> 2.6.0'
  s.add_dependency 'ruby-ip', '~> 0.9.3'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
end
