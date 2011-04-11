module Mule
  class Configurator
    
    attr_reader :jobs, :events
    
    def initialize(config_path)
      @config        = config_path
      @jobs          = []
      @events        = {
        :before_fork => Proc.new {},
        :after_fork  => Proc.new {}
      }
    end
    
    def parse!
      instance_eval(config_content)
    end
    
    def config_content
      raise Mule::Error::MissingConfig unless File.exists?(@config)
      File.read(@config)
    end
    
    def add_job(&block)
      if block_given?
        job = Job.new
        yield job
        @jobs << job
      end
    end
    
    def before_fork(&block)
      @events[:before_fork] = block if block_given?
    end
    
    def after_fork(&block)
      @events[:after_fork] = block if block_given?
    end
    
  end
end
