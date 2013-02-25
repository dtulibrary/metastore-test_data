require "metastore-test_data/version"

module Metastore
  module TestData
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load "tasks/metastore-test_data.rake"
      end
    end
  end
end
