require 'fileutils'
require 'rsolr'
require 'nokogiri'

namespace :metastore do

  $solr_config = YAML.load_file(Rails.root + 'config/solr.yml')[Rails.env]
  namespace :testdata do

    desc "Fetch from local repository and index"
    task :setup_index => ['jetty:stop', :setup, 'jetty:start', :index]

    desc "Index fixtures"
    task :index => :environment do
      puts "Indexing"
      solr = RSolr.connect :url => $solr_config["url"]
      solr.delete_by_query '*:*'
      xml = File.open("spec/fixtures/solr_data.xml", "r").read
      solr.update :data => xml
      solr.commit

      puts "Indexing toc"
      solr = RSolr.connect :url => $solr_config["toc_url"]
      solr.delete_by_query '*:*'
      xml = File.open("spec/fixtures/toc_data.xml", "r").read
      solr.update :data => xml
      solr.commit

    end

    desc "Install solr configuration files and fixtures for development and test"
    task :setup => 'setup:local'

    namespace :setup do

      $config = {
        :name             => "metastore-test",
        :version          => "1.0-SNAPSHOT",
        :group            => "dk/dtu/dtic",
        :maven_local_path => "#{ENV['HOME']}/.m2/repository/",
        :maven_dtic_path  => "http://maven.cvt.dk/",
      }

      if Rails.application.config.respond_to? :metastore
        $config = $config.merge(Rails.application.config.metastore)
      end


      desc "Fetch from local repository"
      task :local => :environment do
        puts "Fetching from local maven repository..."

        file_path = "#{$config[:maven_local_path]}#{$config[:group]}/#{$config[:name]}/#{$config[:version]}/#{$config[:name]}-*.tar"
        Dir.glob(file_path).each do |f|
          puts "Extracting"
          `tar xf #{f} -C /tmp/`
        end

        install_solr($config)
      end

      desc "Fetch from DTIC maven repository"
      task :maven => :environment do
        fetch_from_maven($config, false)
        install_solr($config)
      end

      desc 'Fetch from DTIC maven repository asking for password'
      task :maven_pw => :environment do
        fetch_from_maven($config, true)
        install_solr($config)
      end
    end

    desc 'Clean up jetty solr setup'
    task :clean do
      FileUtils.rm_r Dir.glob('jetty')
      FileUtils.rm_f "config/solr.yml"
      FileUtils.rm_f "config/jetty.yml"
    end

  end

  def fetch_from_maven(config, using_password)
    puts "Fetching from DTIC maven repository..."
    
    if using_password
      hl = HighLine.new
      user = hl.ask 'User: '
      password = hl.ask('Password: ') { |q| q.echo = '*' }
    else
      user = password = nil
    end
    revision = get_latest_snapshot(config, user, password)
    extract_snapshot(config, revision, user, password)
  end

  def get_latest_snapshot(config, user, password)
    metadata_path = "#{config[:maven_dtic_path]}#{config[:group]}/#{config[:name]}/#{config[:version]}/maven-metadata.xml"
    if password
      `wget --user=#{user} --password=#{password} -O /tmp/maven-metadata.xml #{metadata_path} --progress=dot:mega`
    else
      `wget -O /tmp/maven-metadata.xml #{metadata_path} --progress=dot:mega`
    end
    metadata = Nokogiri::XML(File.read('/tmp/maven-metadata.xml'))
    revision = metadata.xpath("//snapshotVersions/snapshotVersion[extension='tar']/value/text()")
  end

  def extract_snapshot(config, revision, user, password)
    file_name = "#{config[:name]}-#{revision}.tar"
    file_path = "#{config[:maven_dtic_path]}#{config[:group]}/#{config[:name]}/#{config[:version]}/#{file_name}"

    if password
      `wget --user=#{user} --password=#{password} -O /tmp/#{file_name} #{file_path} --progress=dot:mega`
    else
      `wget -O /tmp/#{file_name} #{file_path} --progress=dot:mega`
    end
    puts "Extracting"
    `rm -rf /tmp/#{config[:name]}`
    `tar xf /tmp/#{file_name} -C /tmp/`

  end

  def install_solr(config)

    # install Solr dependencies
    dependencies_dir = "jetty/lib/ext"
    FileUtils.mkdir_p(dependencies_dir)
    FileUtils.cp_r(Dir.glob("/tmp/#{config[:name]}/lib/*.jar"), dependencies_dir)

    tmp_path = "/tmp/#{config[:name]}/solr"

    # install solr.war
    Dir["#{tmp_path}-*.war"].each do |f|
      FileUtils.cp(f, "jetty/webapps/solr.war")
    end

    # install Solr plugins
    plugin_dir = "jetty/solr/lib"
    FileUtils.mkdir_p(plugin_dir)
    FileUtils.cp_r(Dir.glob("#{tmp_path}/lib/*.jar"), plugin_dir)

    # install metastore configuration
    tmp_conf_path = "#{tmp_path}/metastore/conf"
    jetty_conf = "jetty/solr/metastore/conf"

    puts "Creating solr configuration and data directories"
    FileUtils.mkdir_p(jetty_conf)
    FileUtils.mkdir_p("jetty/solr/metastore/data")

    puts "Copying solr configuration files"
    Dir["#{tmp_conf_path}/*.{html,txt,xml}","#{tmp_conf_path}/*/"].each do |f|
      FileUtils.cp_r(f, jetty_conf)
    end
    FileUtils.mkdir_p("spec/fixtures")
    FileUtils.cp("/tmp/#{config[:name]}/solr_data.xml", "spec/fixtures")

    # install toc configuration
    tmp_conf_path = "#{tmp_path}/toc/conf"
    jetty_conf = "jetty/solr/toc/conf"

    puts "Creating toc solr configuration and data directories"
    FileUtils.mkdir_p(jetty_conf)
    FileUtils.mkdir_p("jetty/solr/toc/data")

    puts "Copying toc solr configuration files"
    Dir["#{tmp_conf_path}/*.{html,txt}","#{tmp_conf_path}/*/"].each do |f|
      FileUtils.cp_r(f, jetty_conf)
    end
    FileUtils.cp("#{tmp_conf_path}/solrconfig.xml", "#{jetty_conf}/solrconfig.xml")
    FileUtils.cp(%W(#{tmp_conf_path}/schema.xml), "#{jetty_conf}")
    FileUtils.mkdir_p("spec/fixtures")
    FileUtils.cp("/tmp/#{config[:name]}/toc_data.xml", "spec/fixtures")


    File.open("#{jetty_conf}/../../solr.xml", 'w').write(
      "<?xml version='1.0' encoding='UTF-8'?>\n"\
      "<solr persistent='true' sharedLib='lib'>\n"\
      "  <cores adminPath='/admin/cores'>\n"\
      "    <core name='metastore' instanceDir='metastore' />\n"\
      "    <core name='toc' instanceDir='toc' />\n"\
      "  </cores>\n"\
      "</solr>\n"
    )

    FileUtils.rm_rf "/tmp/#{config[:name]}*"
    FileUtils.rm_rf "jetty/solr/data/index"

  end

  def scramble(in_file, out_file)

    in_f = File.open(in_file)
    doc = Nokogiri::XML(in_f)
    in_f.close

    doc.root.children.each do |node|
      if node.name == 'doc'
        node.children.each do |field_node|
          if !['format','access', 'cluster_id', 'source_type', 'pub_date'].include? field_node['name']
            field_node.content = field_node.content.split(//).shuffle.join
          end
        end
      end
    end

    File.open(out_file, 'w') do |out_f|
      out_f.write doc
    end

  end

end
