require 'rubygems'
require 'json'
require 'uri'

module TorqueSpec
  module AS7

    def port
      9990
    end

    def start_command
      "#{ENV['JAVA_HOME']}/bin/java #{TorqueSpec.jvm_args} -Dorg.jboss.resolver.warning=true -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Dorg.jboss.boot.log.file=#{TorqueSpec.jboss_home}/standalone/log/boot.log -Dlogging.configuration=file:#{TorqueSpec.jboss_home}/standalone/configuration/logging.properties -jar #{TorqueSpec.jboss_home}/jboss-modules.jar -mp #{TorqueSpec.jboss_home}/modules -logmodule org.jboss.logmanager -jaxpmodule javax.xml.jaxp-provider org.jboss.as.standalone -Djboss.home.dir=#{TorqueSpec.jboss_home}"
    end

    def shutdown
      domain_api( :operation => "shutdown" )
    rescue EOFError
      # ignorable
    end

    def _deploy(path)
      url = urlify(path)
      domain_api( :operation => "add",
                  :address   => [ "deployment", url ],
                  :url       => url )
      domain_api( :operation => "deploy",
                  :address   => [ "deployment", url ] )
    end

    def _undeploy(path)
      domain_api( :operation => "remove",
                  :address   => [ "deployment", urlify(path) ] )
    end

    def ready?
      response = JSON.parse( domain_api( :operation => "read-attribute",
                                         :name      => "server-state") )
      response['outcome']=='success' && response['result']=='RUNNING'
    rescue
      false
    end

    private

    def domain_api(params)
      post('/domain-api', params.to_json)
    end

    def urlify(path)
      URI.parse(path).scheme.nil? ? "file:#{path}" : path
    end

  end
end
