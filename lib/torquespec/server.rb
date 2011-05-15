require 'net/http'
require 'torquespec/as6'

module TorqueSpec
  class Server

    def initialize
      self.extend AS6
    end

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
          self.stopped = false
        end
      end
      startup(opts)
    end

    def stop
      return if stopped
      self.stopped = true
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
      _deploy(url)
      puts "  deployed in #{(Time.now - t0).to_i}s"
    end

    def undeploy(url)
      _undeploy(url)
      puts "  undeployed #{url.split('/')[-1]}"
    end

    def wait_for_ready(timeout)
      puts "Waiting up to #{timeout}s for JBoss to boot"
      t0 = Time.now
      while (Time.now - t0 < timeout && !stopped) do
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
      cmd = start_command
      process = IO.popen( cmd )
      Thread.new(process) { |console| while(console.gets); end }
      %w{ INT TERM KILL }.each { |signal| trap(signal) { stop } }
      puts "#{cmd}\npid=#{process.pid}"
      wait > 0 ? wait_for_ready(wait) : process.pid
    end

    def post(path, params)
      req = Net::HTTP::Post.new(path)
      req.set_form_data( params )
      http( req )
    end

    def http req
      res = Net::HTTP.start('localhost', port) do |http| 
        http.read_timeout = 180
        http.request(req)
      end
      unless Net::HTTPSuccess === res
        STDERR.puts res.body
        res.error!
      end
      res.body
    end

    attr_accessor :stopped
  end

end

