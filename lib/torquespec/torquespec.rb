# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'torquespec/deployment_descriptor'
require 'java'

module TorqueSpec

  # Accepts any combination of hashes, filenames, or heredocs
  def deploy(*descriptors, &block)
    metaclass = class << self; self; end
    metaclass.send(:define_method, :deploy_paths) do
      return @deploy_paths if @deploy_paths
      descriptors += [block.call].flatten if block
      i = descriptors.size > 1 ? 0 : nil
      if respond_to?(:display_name)
        @deploy_paths = descriptors.map do |descriptor| 
          DeploymentDescriptor.new(descriptor, 
                                   "#{self.display_name}#{i&&i-=1}", 
                                   descriptors.last==descriptor && descendants.any? {|x| x.is_a?(TorqueSpec::Daemon::Client)}
                                   ).path
        end
      else
        @deploy_paths = descriptors.map do |descriptor| 
          DeploymentDescriptor.new(descriptor, 
                                   "#{self.description}#{i&&i-=1}", 
                                   descriptors.last==descriptor && descendants.any? {|x| x.is_a?(TorqueSpec::Daemon::Client)}
                                   ).path
        end
      end
    end
  end

  class << self
    attr_accessor :knob_root, :jboss_home, :jvm_args, :max_heap, :lazy, :drb_port, :spec_dir, :domain_mode, :verbose, :default_deploy 
    def configure
      yield self
    end
    def jvm_args
      max_heap ? @jvm_args.sub(/-Xmx\w+/, "-Xmx#{max_heap}") : @jvm_args
    end
    def as7?
      File.exist?( File.join( jboss_home, "bin/standalone.sh" ) )
    end
    def jboss_home
      @jboss_home ||= ENV['JBOSS_HOME'] || jboss_home_from_server_gem
    end
    def jruby_home
      ENV['JRUBY_HOME'] || File.expand_path(java.lang.System.getProperty('jruby.home'))
    end
    def java_home
      ENV['JAVA_HOME'] || File.expand_path(java.lang.System.getProperty('java.home'))
    end
    def jboss_home_from_server_gem
      require 'torquebox-server'
      TorqueBox::Server.jboss_home
    rescue Exception
      $stderr.puts "WARN: Unable to determine JBoss install location; set either TorqueSpec.jboss_home or ENV['JBOSS_HOME']"
    end
    def verbose?
      @verbose
    end
  end

  def self.on_windows?
    java.lang::System.getProperty( "os.name" ) =~ /windows/i
  end
  

  # A somewhat hackish way of exposing client-side gems to the server-side daemon
  def self.rubylib
    here = File.dirname(__FILE__)
    rspec_libs = Dir.glob(File.expand_path(File.join(here, "../../..", "*{rspec,diff-lcs}*/lib")))
    this_lib = File.expand_path(File.join(here, ".."))
    rspec_libs.unshift( this_lib ).join(on_windows? ? ";" : ":")
  end

  # We must initialize the daemon with the same params as passed to the client
  def self.argv
    ( ARGV.empty? ? [ 'spec' ] : ARGV )
  end

  # The location of an empty app used for deploying the daemon
  def self.app_root
    File.expand_path( File.join( File.dirname(__FILE__), "../..", "apps", "empty" ) )
  end

  # Whether we're running locally or in the daemon
  def self.remote?
    !!ENV['TORQUEBOX_APP_NAME']
  end
  
  # Guard those things you only want to do in the container
  def self.remote
    yield if remote?
  end
  
  # Guard those things you only want done locally
  def self.local
    yield unless remote?
  end

end

# Default TorqueSpec options
TorqueSpec.configure do |config|
  config.drb_port = 7772
  config.knob_root = ".torquespec"
  config.default_deploy = 'default_deploy.yml'
  config.domain_mode = %w(yes true 1).include?(java.lang.System.getProperty('domain.mode') || ENV['DOMAIN_MODE'])
  config.jvm_args = "-Xms64m -Xmx1024m -XX:MaxPermSize=512m -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -Djruby.home=#{config.jruby_home}"
  config.verbose = true
end


