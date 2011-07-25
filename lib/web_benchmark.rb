require 'net/http'

class WebBenchmark
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

    @quiet       = true
  end

  def start
    threads = []
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

    self.class.store(url, start, Time.now, res.code)

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

      return if next_url.nil?

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
    return if !!@quiet
    $stderr.puts msg
  end

end



