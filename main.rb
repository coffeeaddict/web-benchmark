#!/opt/ree/bin/ruby

require 'rubygems'
require 'bundler/setup'
require 'nokogiri'

require './lib/web_benchmark'
require './lib/statistics'

class Time
  def before?(other)
    self < other
  end

  def after?(other)
    self > other
  end
end

url   = ARGV[0] || "http://devschuur.simplic.it/yoshikai/"
count = (ARGV[1] || 5).to_i
conc  = (ARGV[2] || 5).to_i

start = Time.now
wb = WebBenchmark.new(url, count, conc)
wb.start
puts "Benchmark took: #{"%.2f" % (Time.now - start)}"

stats = WebBenchmark.stats

total    = 0
avg      = []
conc_req = []
requests = stats.collect { |url, info| info }.flatten

requests.each do |request|
  time  = request[:stop] - request[:start]
  total += time
  avg   << time

  (requests - conc_req - [request]).each do |other|
    if other[:start].after?(request[:start]) and other[:start].before?(request[:stop])
      # puts "#{other[:start].to_i} between #{request[:start].to_i} and #{request[:stop].to_i}"
      conc_req << other
    end
  end
end

mean    = Statistics.mean(avg)
std_dev = Statistics.standard_deviation(avg)

puts "Attempted: #{count * conc} requests"
puts "Performed: #{requests.count} requests"
puts "Total time spent: #{"%.2fs" % total}"
puts "Avg time spent: #{"%.2fs" % mean} - std dev: #{"%.2fs" % std_dev}"
puts "Concurrent requests: #{conc_req.count}"