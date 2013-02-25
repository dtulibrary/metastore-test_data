require 'fileutils'

module Metastore
  module TestData
    module Generators
      class InstallGenerator < Rails::Generators::Base
        def install
          ['config/solr.yml', 'config/jetty.yml'].each do |f|
            FileUtils.cp File.expand_path(f, InstallGenerator.source_root), File.expand_path(f, Rails.root)
          end

          FileUtils.cp_r File.expand_path('jetty', InstallGenerator.source_root), Rails.root
        end

        def self.source_root
          @source_root ||= File.expand_path("../../../..", File.dirname(__FILE__))
        end
      end
    end
  end
end
