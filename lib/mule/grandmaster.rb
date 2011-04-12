module Mule
  class Grandmaster
    
    CHILDREN = []
    
    SIG_QUEUE = []
    
    QUEUE_SIGS = [:QUIT, :INT, :TERM, :USR2]
    
    def initialize(config_file)
      @config_file = config_file
    end
    
    def start
      # trap sigs
      QUEUE_SIGS.each do |sig|
        trap(sig) {SIG_QUEUE << sig; wakeup}
      end
      exec_child
      sleep
    end
    
    def exec_child
      # create configurator instance
      configurator = Configurator.new(@config_file).parse!
      
      # start master
      pid = fork do
        Master.new(configurator).start
      end
      CHILDREN << pid
      pid
    end
    
    def wakeup
      case SIG_QUEUE.shift
      when :INT, :TERM
        reap_children
        exit
      when :QUIT
        reap_children(true)
        exit
      when :USR2
        new_child = exec_child
        reap_children(true, [new_child])
        sleep
      end
    end
    
    def reap_children(graceful=false, grant_amnesty=[])
      CHILDREN.each do |pid|
        begin
          unless grant_amnesty.include?(pid)
            Process.kill((graceful)? :QUIT : :TERM , pid)
            Process.detach(pid)
            CHILDREN.delete(pid)
          end
        rescue Errno::ESRCH, Errno::ENOENT
          # do nothing, we don't care if were missing a pid that we're
          # trying to murder already
        end
      end
    end
    
  end
end