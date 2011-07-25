require './lib/fetcher'
require './lib/results'
require './lib/interpretor'

# Perform a visitors benchmark on a web resource (be it app or site)
#
# == Drill down
# * Start X threads
# * Let each thread perform an average of Y requests (count -/+ rand(count))
# * Make sure the user waits < Z seconds before requesting the next page
#
# This way you can mimic a number of visitors on your site and see what that
# does for
# * The load on your webserver (keep an eye on that!)
# * The speed per request
#
# == Assets
# By default each visitor will request the assets (img, script, css) it
# encounters (unless seen before). The time it takes to load these assets is
# added to the request time
#
class WebBenchmark
  VERSION='1.0.0'

  attr_accessor :start_point, :visitors, :count, :noisy, :include_assets

  def initialize(start_point, count=5, visitors=2, sleep=500)
    @start_point = start_point
    @visitors    = visitors
    @count       = count

    sleep *= 100 if sleep < 100
    @sleep = sleep

    @noisy          = false
    @include_assets = true
  end

  # Perform a full test - this will show you how things 'scale'
  #
  # First, a base line is established by performing #count visits with only
  # one #visitors. This would generate a sample that should serve as the
  # 'nominal' operation of the resource
  #
  # Then we let things cool down for some seconds and perform a test with only
  # half the number of visitors requested
  #
  # Cool down again and finaly go in full blast.
  #
  # You will be handed an interpretor holding 3 result sets to play with
  #
  def full_test(cool_down=5)
    puts "Perfoming a full test"
    interpretor = Interpretor.new(false)

    visitors_before  = self.visitors

    puts "Determening base line"
    # first, establish a base line 1 client - 20 requests
    self.visitors = 1
    self.start

    interpretor.sets << Results.get_all
    Results.clear

    puts "Letting the server cool down #{cool_down}s"
    sleep cool_down

    puts "\n:: Half strength test"
    self.visitors = visitors_before / 2
    self.start

    interpretor.sets << Results.get_all
    Results.clear

    puts "Letting the server cool down #{cool_down}s"
    sleep cool_down

    puts "\n:: Full strength test"
    self.visitors = visitors_before

    self.start

    interpretor.sets << Results.get_all

    return interpretor
  end

  # start all #visitors
  #
  def start
    threads = []

    start = Time.now

    puts "Starting benchmark #{@count}/#{@visitors}..."
    @visitors.times { |i|
      threads << Thread.new(@start_point, @count) do |url, count|
        Thread.current[:count]        = (
          rand(2) == 1 ? count - rand(count) : count + rand(count)
        )
        Thread.current[:name]         = "[Visitor-#{i+1}]"
        Thread.current[:assets_cache] = []

        benchmark(url)
      end
    }

    shout "Waiting for #{threads.count} threads"
    threads.collect(&:join)

    puts "Benchmark took: #{"%.2f" % (Time.now - start)}"
    return
  end

  # how well does the resource perform.
  #
  # The total time of the request is stored in WebBenchmark::Results
  #
  # before the benchmark is started, a sleep time is introduced. This helps to
  # spread out (and randomize) the #visitors
  #
  # The requested page is analyzed and a next link is choosen if the visitor
  # still has pages left to visit
  #
  def benchmark(url)
    me = Thread.current

    if @sleep != 0
      slumber = ((rand(@sleep)+1)/100.0)
      shout "#{me[:name]}: sleep #{slumber}"

      Kernel::sleep(slumber)
    end

    shout "#{me[:name]}:#{me[:count]} : #{url}"

    fetcher = Fetcher.new(url)
    res = fetcher.fetch

    if res == false
      shout "#{me[:name]}: error on #{url}"
      return
    end

    if @include_assets == true and !fetcher.body.nil?
      fetched = fetcher.fetch_assets(me[:assets_cache])
      shout("Fetched assets: #{fetched.join(", ")}")
      me[:assets_cache] += fetched
    end

    r = Results.instance(url)
    r.record(fetcher.start, fetcher.stop, fetcher.result.status)

    links = []
    if fetcher.body
      fetcher.body.css('a').each do |a|
        link = a[:href]
        if link =~ /^\//
          link = @start_point + link

        elsif link !~ /https?:/
          begin
            base = url.gsub(/[^\/]+$/, '')
            link = base + link
          rescue
          end
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
        shout("Cannot find another link on #{url} #{fetcher.result.status}- restarting on start point")
        return benchmark(@start_point)
      end

      benchmark(next_url.gsub(/([^:])\/\//, '\1/'))
    end
  end

  # fetch the page
  def fetch(uri)

    res = sess.get(uri)

    return [ res, sess ]

  rescue Exception, Timeout::Error => e
    shout "Error: #{e.message}"
    nil
  end

  def shout msg
    return if !@noisy
    $stderr.puts msg
  end

end



