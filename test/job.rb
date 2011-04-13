#!/usr/bin/env ruby

loop do
  open('output.txt', 'a') do |f|
    f << "#{Time.now}\n"
  end
  sleep 1
end
