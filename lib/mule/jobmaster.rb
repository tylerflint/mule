module Mule
  class Jobmaster

    QUEUE_SIGS = [:QUIT, :INT, :TERM]

    def initialize(configurator, job)
      @configurator = configurator
      @job          = job
    end

    def children
      @children ||= []
    end
    
    def sig_queue
      @sig_queue ||= []
    end

    def start
      puts "MULE: (#{Process.pid}) jobmaster starting"
      exec_children
      # trap sigs
      QUEUE_SIGS.each do |sig|
        trap(sig) {sig_queue << sig; wakeup}
      end
      sleep
    end

    def wakeup
      puts "MULE: (#{Process.pid}) jobmaster waking up"
      case sig_queue.shift
      when :QUIT
        puts "MULE: (#{Process.pid}) jobmaster received QUIT signal"
        reap_children(true)
        exit
      when :INT, :TERM
        puts "MULE: (#{Process.pid}) jobmaster received TERM signal"
        reap_children
        exit
      end
    end

    def exec_children
      @configurator.events[:after_fork].call
      @job.events[:before_fork].call
      job_content = File.read(@job.file)
      @job.workers.times do
        pid = fork do
          puts "MULE: (#{Process.pid}) job starting"
          clean
          @job.events[:after_fork].call
          eval job_content
        end
        children << pid
      end
    end

    def reap_children(graceful=false)
      children.each do |pid|
        begin
          if graceful
            puts "MULE: (#{Process.pid}) jobmaster gracefully killing job worker"
          else
            puts "MULE: (#{Process.pid}) jobmaster brutally murdering job worker"
          end
          Process.kill((graceful)? :QUIT : :TERM , pid)
          children.delete(pid)
        rescue Errno::ESRCH, Errno::ENOENT
          # do nothing, we don't care if were missing a pid that we're
          # trying to murder already
        end
      end
      # wait for all the children to die
      Process.waitall
      puts "MULE: (#{Process.pid}) jobmaster killed job workers, retiring to the grave"
    end
    
    def clean
      children = []
      sig_queue = []
    end
  end
end
