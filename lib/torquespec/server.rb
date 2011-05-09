require 'net/http'

module TorqueSpec
  class Server
    
    def start(opts={})
      if ready?
        if TorqueSpec.lazy
          puts "Using running JBoss (try lazy=false if you get errors)"
          return
        else
          stop
          puts "Waiting for running JBoss to shutdown"
          sleep(5)
          sleep(1) while ready?
        end
      end
      startup(opts)
    end

    def stop
      if TorqueSpec.lazy
        puts "JBoss won't be stopped (lazy=true)"
      else
        shutdown
        puts "Shutdown message sent to JBoss"
      end
    end

    def deploy(url)
      t0 = Time.now
      puts "#{url}"
      success?( deployer( 'redeploy', url ) )
      puts "  deployed in #{(Time.now - t0).to_i}s"
    end

    def undeploy(url)
      success?( deployer( 'undeploy', url ) )
      puts "  undeployed #{url.split('/')[-1]}"
    end

    def ready?
      response = jmx_console( :action => 'inspectMBean', :name => 'jboss.system:type=Server' )
      "True" == response.match(/>Started<.*?<pre>\s+^(\w+)/m)[1]
    rescue
      false
    end

    def wait_for_ready(timeout)
      puts "Waiting up to #{timeout}s for JBoss to boot"
      t0 = Time.now
      while (Time.now - t0 < timeout) do
        if ready?
          puts "JBoss started in #{(Time.now - t0).to_i}s"
          return true
        end
        sleep(1)
      end
      raise "JBoss failed to start"
    end

    protected

    def startup(opts)
      wait = opts[:wait].to_i
      cmd = command
      process = IO.popen( cmd )
      Thread.new(process) { |console| while(console.gets); end }
      %w{ INT TERM KILL }.each { |signal| trap(signal) { stop } }
      puts "#{cmd}\npid=#{process.pid}"
      wait > 0 ? wait_for_ready(wait) : process.pid
    end

    def shutdown
      success?( jmx_console( :action     => 'invokeOpByName', 
                             :name       => 'jboss.system:type=Server', 
                             :methodName => 'shutdown' ) )
    end

    def command
      java_home = java.lang::System.getProperty( 'java.home' )
      "#{java_home}/bin/java -cp #{TorqueSpec.jboss_home}/bin/run.jar #{TorqueSpec.jvm_args} -Djava.endorsed.dirs=#{TorqueSpec.jboss_home}/lib/endorsed org.jboss.Main -c #{TorqueSpec.jboss_conf} -b #{TorqueSpec.host}"
    end

    def deployer(method, url)
      jmx_console( :action     => 'invokeOpByName', 
                   :name       => 'jboss.system:service=MainDeployer', 
                   :methodName => method,
                   :argType    => 'java.net.URL', 
                   :arg0       => url )
    end

    def success?(response)
      response.include?( "Operation completed successfully" )
    end

    def jmx_console(params)
      req = Net::HTTP::Post.new('/jmx-console/HtmlAdaptor')
      req.set_form_data( params )
      http( req )
    end

    def http req
      res = Net::HTTP.start(TorqueSpec.host, TorqueSpec.port) do |http| 
        http.read_timeout = 180
        http.request(req)
      end
      unless Net::HTTPSuccess === res
        STDERR.puts res.body
        res.error!
      end
      res.body
    end

  end

end

