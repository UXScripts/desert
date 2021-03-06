# Don't change this file. Configuration is done in config/environment.rb and config/environments/*.rb
require "fileutils"

unless defined?(RAILS_ROOT)
  root_path = File.join(File.dirname(__FILE__), '..')

  unless RUBY_PLATFORM =~ /(:?mswin|mingw)/
    require 'pathname'
    root_path = Pathname.new(root_path).cleanpath(true).to_s
  end

  RAILS_ROOT = root_path
end

unless defined?(Rails::Initializer)
  rails_dir = "#{RAILS_ROOT}/vendor/rails"
  if ENV['RAILS_VERSION']
    rails_version = ENV['RAILS_VERSION']
    rails_versions_dir = "#{RAILS_ROOT}/vendor/rails_versions/#{ENV['RAILS_VERSION'].downcase}"

    system("rm -f #{rails_dir}")
    system("ln -s #{rails_versions_dir} #{rails_dir}")
  else
    FileUtils.cd(rails_dir) do
      rails_version = File.basename(Dir.pwd)
    end
  end

  Dir["#{rails_dir}/*"].each do |path|
    $:.unshift("#{path}/lib") if File.directory?("#{path}/lib")
  end
  initializer_path = "#{rails_dir}/railties/lib/initializer.rb"
  unless File.exists?(initializer_path)
    raise "#{initializer_path} not in vendor. Run rake install_dependencies"
  end

  if rails_version == "edge" || (rails_version.split(".").map {|version| Integer(version)} <=> [2, 1, 0]) >= 0
    require "#{rails_dir}/railties/environments/boot"
  else
    require "#{rails_dir}/railties/lib/initializer"
  end

  Rails::Initializer.run(:set_load_path)
end
