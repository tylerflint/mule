module Mule
  class Master
    CHILDREN = []
    
    SIG_QUEUE = []
    
    QUEUE_SIGS = [:QUIT, :INT, :TERM]
    
    def initialize(configurator)
      @configurator = configurator
    end
    
    def start
      # trap sigs
      QUEUE_SIGS.each do |sig|
        trap(sig) {SIG_QUEUE << sig; wakeup}
      end
      exec_children
      sleep
    end
    
    def wakeup
      case SIG_QUEUE.shift
      when :QUIT
        reap_children(true)
        exit
      when :INT, :TERM
        reap_children
        exit
      end
    end
    
    def exec_children
      @configurator.events[:before_fork].call
      @configurator.jobs.each do |job|
        pid = fork do
          Jobmaster.new(@configurator, job).start
        end
        CHILDREN << pid
      end
    end
    
    def reap_children(graceful=false)
      CHILDREN.each do |pid|
        begin
          Process.kill((graceful)? :QUIT : :TERM , pid)
          CHILDREN.delete(pid)
        rescue Errno::ESRCH, Errno::ENOENT
          # do nothing, we don't care if were missing a pid that we're
          # trying to murder already
        end
      end
      # wait for all the children to die
      Process.waitall
    end
  end
end