module Mule
  class Jobmaster
    include Log

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
      log "jobmaster starting"
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
        log "jobmaster received QUIT signal"
        reap_children(true)
      when :INT, :TERM
        log "jobmaster received TERM signal"
        reap_children
      end
    end

    def exec_children
      @configurator.events[:after_fork].call
      @job.events[:before_fork].call
      job_content = File.read(@job.file)
      @job.workers.times do
        pid = fork do
          worker = Worker.new
          worker.run(job_content)
        end
        children << pid
      end
    end

    def reap_children(graceful=false)
      children.each do |pid|
        begin
          if graceful
            log "jobmaster gracefully killing job worker"
          else
            log "jobmaster brutally murdering job worker"
          end
          Process.kill((graceful)? :QUIT : :TERM , pid)
          sleep(0.1)
        rescue Errno::ESRCH, Errno::ENOENT => e
          # do nothing, we don't care if were missing a pid that we're
          # trying to murder already
          log "jobmaster error: #{e}"
        end
      end
      children = []
      # wait for all the children to die
      Process.waitall
      log "jobmaster killed job workers, retiring to the grave"
    end
    
    def clean
      children = []
      sig_queue = []
    end
  end
end
