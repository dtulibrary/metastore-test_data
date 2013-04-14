# Metastore::TestData

Generators and tasks to install jetty and fetch test-data from metastore project

## Installation

Add to your application's Gemfile:

    gem 'jettywrapper'
    gem 'metastore-test_data', :github => 'dtulibrary/metastore-test_data'

And then execute:

    $ bundle install


## Usage

Run: 
    
    rails generate metastore:test_data:install
    
    rake metastore:testdata:setup
    rake jetty:start
    rake metastore:testdata:index

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
