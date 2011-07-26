#!/opt/ree/bin/ruby

require 'rubygems'
require 'bundler/setup'
require 'getopt/std'

require './lib/web_benchmark'

opts = Getopt::Std.getopts("hvfar:c:C:s:")
url  = ARGV[0]

if !opts["h"] and url.nil?
  $stderr.puts "Need an url to benchmark - the site root is usually best\n\n"
  opts["h"] = 1
end

if opts["h"]
  puts %Q{#{$0} -- Perform a web benchmark

SYNOPSIS
#{$0} [options] http://www.yourdomain.com/

OPTIONS
  -h                   : Print this screen and exit
  -v                   : Be verbose
  -f                   : Perform a full test
  -a                   : Do not fetch assets
  -r requests          : The number of requests each visitor should perform on
                         average (default 3)
  -c visitors_count    : The number of visitors to launch (default 5)
  -C seconds           : The number of seconds to cool down in a full test
                         (default 10)
  -s seconds           : Sleep less then X seconds between requests. Specify
                         times 100 (default 2000 [= 20 seconds]).
                         Specify 0 if you don't want the visitors to sleep
                         between requests.


VISITORS
  The Web Benchmark simulates visitors to your online resource. It creates
  the number of specified visitors and they click random links on your page.

  Each visitor has a pre determined number of pages to visit around the
  number you have specified, where N = n [-|+] rand(n)  [n = specified nr]

  Each visitor has a seperate cache for assets and doesn't download an asset
  twice.


FULL TEST
  Wen performing a full test, the benchmark is conducted 3 times. First with
  only one visitor, to establish a base line.

  Then with half the visitors, and finally with all the visitors.

  You can set a cool down period between the tests. Between tests visitors and
  caches are destroyed
}
  exit
end


# use easy-going defaults
count    = (opts["r"] || 3).to_i
visitors = (opts["c"] || 5).to_i
sleep    = (opts["s"] || 2000).to_i

wb = WebBenchmark.new(url, count, visitors, sleep)
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
  puts "\tMin: #{"%.2fs" % base[:min]}, Max: #{"%.2fs" % base[:max]}"
  puts "---\n\n"


  puts ":: Half strength"
  puts "\tAttepmted: #{count * (visitors/2)}"
  puts "\tPerformed: #{half[:sample]}"
  puts "\tConcurrent: #{half[:concurrent]}"
  puts "\tTotal: #{"%.2fs" % half[:total]}"
  puts "\tAvg: #{"%.2fs" % half[:mean]} - std_dev: #{"%.2fs" % half[:std_dev]}"
  puts "\tMin: #{"%.2fs" % half[:min]}, Max: #{"%.2fs" % half[:max]}"
  puts "\t#{"%.2f%%" % half[:slower]} slower"
  puts "---\n\n"

  puts ":: Full strength"
  puts "\tAttepmted: #{count * visitors}"
  puts "\tPerformed: #{full[:sample]}"
  puts "\tConcurrent: #{full[:concurrent]}"
  puts "\tTotal: #{"%.2fs" % full[:total]}"
  puts "\tAvg: #{"%.2fs" % full[:mean]} - std_dev: #{"%.2fs" % full[:std_dev]}"
  puts "\tMin: #{"%.2fs" % full[:min]}, Max: #{"%.2fs" % full[:max]}"
  puts "\t#{"%.2f%%" % full[:slower]} slower"

  puts "---\n\n"

else
  wb.start

  interpretor = WebBenchmark::Interpretor.new()
  info        = interpretor.interpret


  puts "Attempted: #{count * visitors} requests"
  puts "Performed: #{info[:sample]} requests"
  puts "Total request time: #{"%.2fs" % info[:total]}"
  puts "Avg request time: #{"%.2fs" % info[:mean]} - std dev: #{"%.2fs" % info[:std_dev]}"
  puts "Min: #{"%.2fs" % info[:min]}, Max: #{"%.2fs" % info[:max]}"
  puts "Concurrent requests: #{info[:concurrent]}"
end


