module Mule
  module Log
    def log(message)
      puts "MULE: (#{Process.pid}) #{message}"
    end
  end
end