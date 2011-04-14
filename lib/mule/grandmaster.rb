module Mule
  class Grandmaster
    include Log
    
    QUEUE_SIGS = [:QUIT, :INT, :TERM, :USR2]
    
    def initialize(options)
      @config_file = options[:config]
    end
    
    def children
      @children ||= []
    end
    
    def sig_queue
      @sig_queue ||= []
    end
    
    def start
      log "grandmaster starting"
      exec_child
      QUEUE_SIGS.each do |sig|
        trap(sig) {sig_queue << sig; wakeup}
      end
      sleep
    end
    
    def exec_child
      # create configurator instance
      configurator = Configurator.new(@config_file).parse!
      
      # start master
      pid = fork do
        master = Master.new(configurator)
        master.clean
        master.start
      end
      children << pid
      pid
    end
    
    def wakeup
      case sig_queue.shift
      when :INT, :TERM
        log "grandmaster received TERM signal"
        reap_children
      when :QUIT
        log "grandmaster received QUIT signal"
        reap_children(true)
      when :USR2
        log "grandmaster received USR2 signal"
        new_child = exec_child
        reap_children(true, [new_child])
        sleep
      end
    end
    
    def reap_children(graceful=false, grant_amnesty=[])
      children.each do |pid|
        begin
          unless grant_amnesty.include?(pid)
            Process.kill((graceful)? :QUIT : :TERM , pid)
            sleep(0.1)
            Process.detach(pid) if grant_amnesty.any?
          end
        rescue Errno::ESRCH, Errno::ENOENT
          # do nothing, we don't care if were missing a pid that we're
          # trying to murder already
        end
      end
      children = grant_amnesty
      Process.waitall unless grant_amnesty.any?
    end
    
    def clean
      children = []
      sig_queue = []
    end
    
  end
end