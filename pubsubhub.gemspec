# coding: utf-8
lib = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pubsubhub'

Gem::Specification.new do |spec|
  spec.name          = 'pubsubhub'
  spec.version       = PubSubHub::VERSION
  spec.authors       = ['Causes Engineering']
  spec.email         = ['eng@causes.com']
  spec.summary       = %q{Simple event-based publish-subscribe library}
  spec.description = <<-EOS.strip.gsub(/\s+/, ' ')
    PubSubHub allows you to loosen the coupling between components in a system
    by providing a centralized registry of events and listeners that subscribe
    to them.
  EOS
  spec.homepage      = 'https://github.com/causes/pubsubhub'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
