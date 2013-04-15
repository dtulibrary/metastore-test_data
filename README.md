# Metastore::TestData

Generators and tasks to install jetty and fetch test-data from the metastore project

## Installation

Add to your application's Gemfile:

    gem 'jettywrapper'
    gem 'metastore-test_data', :github => 'dtulibrary/metastore-test_data'

And then execute:

    bundle install


## Usage

Initial setup: 
    
    rails generate metastore:test_data:install
    
This will copy Jetty and some configuration into your project directory. After this
you can fetch the latest metastore configuration and test-data into the project by

    rake metastore:testdata:setup:maven
    
(Requires access to the DTIC maven repository. I.e. you must be on the DTIC network). If you want to test 
modified metastore configuration and/or new test-data from a local build of the metastore project you can 
copy from your local maven repository (i.e. from ~/.m2) by 
 
    rake metastore:testdata:setup:local
    
After this you can start a Jetty (hosting a Solr) and index the test data into Solr by

    rake jetty:start
    rake metastore:testdata:index
    
You should now have a Solr available on [http://localhost:8983/solr](http://localhost:8983/solr) with a small set of test data.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
