require 'net/http'
require 'nokogiri'
require './lib/results'
require './lib/interpretor'

class WebBenchmark
  attr_accessor :start_point, :concurrent, :count, :noisy

  def self.store(url, start, stop, status)
    @@stats ||= {}
    @@stats[url] ||= []
    @@stats[url] << { :start => start, :stop => stop, :status => status }
  end

  def self.stats
    @@stats
  end

  def initialize(start_point, count=10, concurrent=2)
    @start_point = start_point
    @concurrent  = concurrent
    @count       = count

    @noisy       = false
  end

  def full_test(cool_down=5)
    puts "Perfoming a full test"
    interpretor = Interpretor.new(false)

    conc_before  = self.concurrent

    puts "Determening base line"
    # first, establish a base line 1 client - 20 requests
    self.concurrent = 1
    self.start

    interpretor.sets << Results.get_all
    Results.clear

    puts "Letting the server cool down"
    sleep cool_down

    puts "Half strength test"
    self.concurrent = conc_before / 2
    self.start

    interpretor.sets << Results.get_all
    Results.clear

    puts "Letting the server cool down"
    sleep cool_down

    puts "Full strength test"
    self.concurrent = conc_before

    self.start

    interpretor.sets << Results.get_all

    return interpretor
  end

  def start
    threads = []

    start = Time.now

    puts "Starting benchmark..."
    shout "Starting #{@concurrent} threads"
    @concurrent.times { |i|
      threads << Thread.new(@start_point, @count) do |url, count|
        Thread.current[:count] = count
        Thread.current[:name]  = "<Thread:#{i}>"
        benchmark(url)
      end
    }

    shout "Waiting for #{threads.count} threads"
    threads.collect(&:join)

    puts "Benchmark took: #{"%.2f" % (Time.now - start)}"
    return
  end

  def benchmark(url)
    me = Thread.current

    shout "#{me[:name]}:#{me[:count]} : Benchmarking #{url}"

    start = Time.now
    res = fetch(url)

    if res.nil?
      shout "#{me[:name]}: error on #{url}"
      return
    end

    r = Results.instance(url)
    r.record(start, Time.now, res.code)

    if res.body
      doc = Nokogiri::HTML(res.body)
      links = []
      doc.css('a').each do |a|
        link = a[:href]
        if link =~ /^\//
          link = @start_point + link

        elsif link !~ /https?:/

          base = url.gsub(/[^\/]+$/, '')
          link = base + link
        end

        links << link unless link !~ Regexp.new(@start_point)
      end
    end

    if me[:count] > 1
      me[:count] -= 1

      next_url = nil
      tries    = 0
      while next_url.nil? and tries < 10
        next_url = links[rand(links.length-1)]
        begin
          URI.parse(next_url)
        rescue
          next_url = nil
        end
        tries += 1
      end

      if next_url.nil?
        shout("Cannot find another link on #{url}")
        return
      end

      slumber = ((rand(500)+1)/100.0)
      shout "#{me[:name]}: sleep #{slumber}"

      Kernel::sleep(slumber)

      benchmark(next_url.gsub(/([^:])\/\//, '\1/'))
    end
  end

  def fetch(uri)
    url = URI.parse(uri)

    req = Net::HTTP::Get.new(url.path)

    Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
  rescue
    nil
  end

  def shout msg
    return if !@noisy
    $stderr.puts msg
  end

end



