require 'mechanize'
require 'nokogiri'

class WebBenchmark
  # A fetcher based on patron
  class Fetcher
    attr_accessor :url, :start, :stop, :result, :body, :session

    def initialize(url, visitor)
      @url = url
      @session = Mechanize.new
      @session.open_timeout = 10
      @session.read_timeout = 300
      @session.user_agent   = "Web-Benchmark/#{WebBenchmark::VERSION}-#{visitor}"
    end

    # fetch the #url and measure the time it took
    def fetch
      @start  = Time.now
      @result = get @url
      @stop   = Time.now

      if @result.code.to_i == 200
        @body = @result.parser
      end

      return @result.code.to_i < 400 ? true : false

    rescue Exception => ex
      @result = FakeResult.new
      $stderr.puts "Ex: #{ex.message}"
      return false

    rescue Patron::TimeoutError, Timeout::Error => ex
      @stop = Time.now
      @result = FakeResult.new
      @result.code = "timeout"

      return false

    end

    def get(uri) # :nodoc:
      @session.get uri
    end

    # fetch the assets on a page. Supply a cache (list of assets not to be
    # fetched)
    #
    # The #stop time is increased with the amount of seconds it took to fetch
    # the assets
    #
    def fetch_assets(cached=[])
      return [] if @body.nil?

      assets = []

      @body.css("img").each do |img|
        assets << img[:src]
      end

      @body.css("script").each do |script|
        next if script[:src].nil? or script[:src] == ""
        assets << script[:src]
      end

      @body.css("link").each do |link|
        next if link[:href].nil? or link[:href] == ""
        assets << link[:href]
      end

      assets -= cached

      start = Time.now
      assets.each do |asset|
        begin
          get asset
        rescue Mechanize::ResponseCodeError, Timeout::Error => ex
          assets -= [asset]
        end
      end
      @stop += (Time.now - start)

      return assets
    end

  end

  class FakeResult
    attr_accessor :code
    attr_reader :body

    def initialize
      @body = nil
      @code = 500
    end
  end
end