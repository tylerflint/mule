module Mule
  class Worker
    include Log
    
    def run(content)
      log "job starting"
      instance_eval(content)
    end
    
  end
end