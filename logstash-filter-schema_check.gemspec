Gem::Specification.new do |s|
  s.name          = "logstash-filter-schema_check"
  s.version       = "0.1.0"
  s.licenses        = ['Apache License (2.0)']
  s.summary       = 'A Logstash plugin to validate JSON schemas'
  s.description     = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
  s.homepage      = "http://www.elastic.co/guide/en/logstash/current/index.html"
  s.authors       = ["Elastic", "Justin Bovee"]
  s.email         = 'jbovee@thehybridtech.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "json-schema"
  s.add_runtime_dependency 'logstash-core-plugin-api', '>= 2.1.1', '<= 2.99'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'logstash-devutils', "~> 1.3", ">= 1.3.1"
end
