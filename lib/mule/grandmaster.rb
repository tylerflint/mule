module Mule
  class Grandmaster
    
    SIG_QUEUE = []
    
    QUEUE_SIGS = [:QUIT, :INT, :TERM, :USR2]
    
    def start
      # create configurator instance
      
      # start master
      
      # trap sigs
      QUEUE_SIGS.each do |sig|
        trap(sig) {SIG_QUEUE << sig; wakeup!}
      end
      
      # sleep forever
      sleep
    end
    
    def wakeup!
      case SIG_QUEUE.shift
      when nil
        # wtf!?
      when :INT, :TERM
        exit
      when :QUIT
        # graceful shutdown
      when :USR2
        # reload
      end
      sleep
    end
    
  end
end