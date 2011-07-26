require 'patron'
require 'nokogiri'

class WebBenchmark
  # A fetcher based on patron
  class Fetcher
    attr_accessor :url, :start, :stop, :result, :body

    def initialize(url, visitor)
      @url = url
      @session = Patron::Session.new
      @session = Patron::Session.new
      @session.timeout = 20
      @session.headers['User-Agent'] = "Web-Benchmark/#{WebBenchmark::VERSION}-#{visitor}"
    end

    # fetch the #url and measure the time it took
    def fetch
      @start  = Time.now
      @result = get @url
      @stop   = Time.now

      if @result.status == 200
        @body = Nokogiri::HTML(@result.body)
      end

      return @result.status < 400 ? true : false

    rescue Exception => ex
      @result = FakeResult.new
      return false

    rescue Patron::TimeoutError, Timeout::Error => ex
      @stop = Time.now
      @result = FakeResult.new
      @result.status = "timeout"

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
        if asset =~ /^\// and @session.base_url.nil?
          puts "Setting base to #{@url} for #{asset}"
          @session.base_url = @url
        end

        begin
          get asset
        rescue Patron::TimeoutError, Timeout::Error => ex
          assets -= [asset]
        end
      end
      @stop += (Time.now - start)

      return assets
    end

  end

  class FakeResult
    attr_accessor :status
    attr_reader :body

    def initialize
      @body = nil
      @status = 500
    end
  end
end