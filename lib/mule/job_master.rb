module Mule
  class JobMaster
      CHILDREN = []

      SIG_QUEUE = []

      QUEUE_SIGS = [:QUIT, :INT, :TERM]

      def initialize(configurator, job)
        @configurator = configurator
        @job          = job
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
        @configurator.events[:after_fork].call
        @job.events[:before_fork].call
        job_content = File.read(@job.file)
        @job.workers.times do
          pid = fork do
            @job.events[:after_fork].call
            eval job_content
          end
          CHILDREN << pid
        end
      end

      def reap_children(graceful=false)
        CHILDREN.each do |pid|
          begin
            Process.kill((graceful): :QUIT ? :TERM , pid)
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
end
