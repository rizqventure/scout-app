desc "Build Scout"
task :build => ["environment", "air:runtime:check", "air:sdk:check", "build:jruby", "build:bundle", "build:bin", "build:staticmatic", "build:config"]

namespace :build do
  %w(development test production).each do |env|
    desc "Build the application for the #{env} environment"
    task "#{env}" do
      ENV["SCOUT_ENV"] = env
      Rake::Task["build"].invoke
    end
  end

  task :jruby => 'environment' do
    FileUtils.mkdir_p(Scout.build_vendor_directory)
    unless File.exists?(Scout.jruby_complete_jar)
      puts "Downloading JRuby Complete #{Scout.jruby_version}..."
      Scout.install_jruby_with_bundler
    end
  end
  
  task :bundle => 'build:jruby' do
    # Do not pass in --without bundle as that sets .bundle/config
    with_env("BUNDLE_WITHOUT" => "build") do
      jruby "gem install -r bundler" unless Scout.jruby_gem_exists?("bundler")
      jruby "bundle install --gemfile src/config/Gemfile"
    end
  end
  
  task :bin do
    FileUtils.cp_r(Scout.src_bin_directory, Scout.build_directory)
  end

  desc "Runs bin/staticmatic build on the current directory"
  task :staticmatic => 'environment' do
    system "staticmatic build #{Scout.root}"
  end

  task :config => 'environment' do
    FileUtils.cp_r Scout.runtime_config_directory, Scout.build_directory
    FileUtils.cp File.join(Scout.config_directory, "#{ENV['SCOUT_ENV']}.xml"), Scout.build_directory
  end

  desc "Clears dev environment by removing the build/ directory"
  task :clean => 'environment' do
    FileUtils.rm_rf(Scout.build_directory)
  end
  
  desc "Runs dev:clean, then dev:setup"
  task :redo => ["build:clean", "build"]
end