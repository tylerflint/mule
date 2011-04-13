module Mule
  class Master
    
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
      puts "MULE: (#{Process.pid}) master starting"
      exec_children
      # trap sigs
      QUEUE_SIGS.each do |sig|
        trap(sig) {sig_queue << sig; wakeup}
      end
      sleep
    end
    
    def wakeup
      puts "MULE: (#{Process.pid}) master waking up"
      case sig_queue.shift
      when :QUIT
        puts "MULE: (#{Process.pid}) master received QUIT signal"
        reap_children(true)
        exit
      when :INT, :TERM
        puts "MULE: (#{Process.pid}) master received TERM signal"
        reap_children
        exit
      end
    end
    
    def exec_children
      change_working_dir
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
    
    def change_working_dir
      dir = @configurator.get_working_directory
      $:.push(dir) unless $:.include?(dir)
      Dir.chdir(dir)
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
      puts "MULE: (#{Process.pid}) master killed jobmasters, retiring to the grave"
    end
    
    def clean
      children = []
      sig_queue = []
    end
  end
end