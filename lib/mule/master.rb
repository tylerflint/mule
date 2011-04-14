module Mule
  class Master
    include Log
    
    QUEUE_SIGS = [:QUIT, :INT, :TERM]
    
    def initialize(configurator)
      @configurator = configurator
    end
    
    def children
      @children ||= []
    end
    
    def sig_queue
      @sig_queue ||= []
    end
    
    def start
      log "master starting"
      exec_children
      # trap sigs
      QUEUE_SIGS.each do |sig|
        trap(sig) {sig_queue << sig; wakeup}
      end
      sleep
    end
    
    def wakeup
      case sig_queue.shift
      when :QUIT
        log "master received QUIT signal"
        reap_children(true)
      when :INT, :TERM
        log "master received TERM signal"
        reap_children
      end
    end
    
    def exec_children
      @configurator.events[:before_fork].call
      @configurator.jobs.each do |job|
        pid = fork do
          jobmaster = Jobmaster.new(@configurator, job)
          jobmaster.clean
          jobmaster.start
        end
        children << pid
      end
    end
    
    def reap_children(graceful=false)
      children.each do |pid|
        begin
          Process.kill((graceful)? :QUIT : :TERM , pid)
          children.delete(pid)
        rescue Errno::ESRCH, Errno::ENOENT
          # do nothing, we don't care if were missing a pid that we're
          # trying to murder already
        end
      end
      # wait for all the children to die
      Process.waitall
      log "master killed jobmasters, retiring to the grave"
    end
    
    def clean
      children = []
      sig_queue = []
    end
  end
end