#!/usr/bin/env ruby

add_job do |j|
  j.file = File.expand_path("../job_config.rb", __FILE__)
  j.workers = 3
end
