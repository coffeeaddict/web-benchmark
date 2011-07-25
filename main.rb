#!/opt/ree/bin/ruby

require 'rubygems'
require 'bundler/setup'
require 'getopt/std'

require './lib/web_benchmark'

opts = Getopt::Std.getopts("r:c:vfC:s:a")

url   = ARGV[0]

raise "Need an url to benchmark - the site root is usually best" if url.nil?

# use easy-going defaults
count = (opts["r"] || 2).to_i
conc  = (opts["c"] || 2).to_i
sleep = (opts["s"] || 500).to_i

wb = WebBenchmark.new(url, count, conc, sleep)
wb.noisy = true if opts["v"]
wb.include_assets = false if opts["a"]

if opts["f"]
  interpretor = wb.full_test((opts['C'] || 10).to_i)
  res = interpretor.compare

  base = res.shift
  half = res.shift
  full = res.shift

  puts ":: Base line"
  puts "\tAttempted: #{count}"
  puts "\tPerformed: #{base[:sample]}"
  puts "\tConcurrent: #{base[:concurrent]}   -- !! THIS SHOULD BE 0"
  puts "\tTotal: #{"%.2fs" % base[:total]}"
  puts "\tAvg: #{"%.2fs" % base[:mean]} - std_dev: #{"%.2fs" % base[:std_dev]}"
  puts "---\n\n"


  puts ":: Half strength"
  puts "\tAttepmted: #{count * (conc/2)}"
  puts "\tPerformed: #{half[:sample]}"
  puts "\tConcurrent: #{half[:concurrent]}"
  puts "\tTotal: #{"%.2fs" % half[:total]}"
  puts "\tAvg: #{"%.2fs" % half[:mean]} - std_dev: #{"%.2fs" % half[:std_dev]}"
  puts "\t#{"%.2f%%" % half[:slower]} slower"
  puts "---\n\n"

  puts ":: Full strength"
  puts "\tAttepmted: #{count * conc}"
  puts "\tPerformed: #{full[:sample]}"
  puts "\tConcurrent: #{full[:concurrent]}"
  puts "\tTotal: #{"%.2fs" % full[:total]}"
  puts "\tAvg: #{"%.2fs" % full[:mean]} - std_dev: #{"%.2fs" % full[:std_dev]}"
  puts "\t#{"%.2f%%" % full[:slower]} slower"

  puts "---\n\n"

else
  wb.start

  interpretor = WebBenchmark::Interpretor.new()
  info        = interpretor.interpret


  puts "Attempted: #{count * conc} requests"
  puts "Performed: #{info[:sample]} requests"
  puts "Total time spent: #{"%.2fs" % info[:total]}"
  puts "Avg time spent: #{"%.2fs" % info[:mean]} - std dev: #{"%.2fs" % info[:std_dev]}"
  puts "Concurrent requests: #{info[:concurrent]}"
end


