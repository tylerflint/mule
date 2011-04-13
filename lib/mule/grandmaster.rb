module Mule
  class Grandmaster
    
    QUEUE_SIGS = [:QUIT, :INT, :TERM, :USR2]
    
    def initialize(config_file)
      @config_file = config_file
    end
    
    def children
      @children ||= []
    end
    
    def sig_queue
      @sig_queue ||= []
    end
    
    def start
      puts "MULE: (#{Process.pid}) grandmaster starting"
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
      puts "MULE: (#{Process.pid}) grandmaster waking up"
      case sig_queue.shift
      when :INT, :TERM
        puts "MULE: (#{Process.pid}) grandmaster received TERM signal"
        reap_children
        exit
      when :QUIT
        puts "MULE: (#{Process.pid}) grandmaster received QUIT signal"
        reap_children(true)
        exit
      when :USR2
        puts "MULE: (#{Process.pid}) grandmaster received USR2 signal"
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
            Process.detach(pid)
            children.delete(pid)
          end
        rescue Errno::ESRCH, Errno::ENOENT
          # do nothing, we don't care if were missing a pid that we're
          # trying to murder already
        end
      end
    end
    
    def clean
      children = []
      sig_queue = []
    end
    
  end
end