# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metastore-test_data/version'

Gem::Specification.new do |gem|
  gem.name          = "metastore-test_data"
  gem.version       = Metastore::TestData::VERSION
  gem.authors       = ["Steffen Elberg Godskesen", "Jimmy Petersen", "Rikke Willer"]
  gem.email         = ["sego@dtic.dtu.dk", "jipe@dtic.dtu.dk", "riwi@dtic.dtu.dk"]
  gem.description   = %q{Provides rake tasks for fetching and indexing solr data}
  gem.summary       = %q{}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("rails")
  gem.add_dependency("jettywrapper")
  gem.add_dependency("nokogiri")
  gem.add_dependency("rsolr")
  gem.add_dependency("highline")
end
