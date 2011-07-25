require 'patron'
require 'nokogiri'

class WebBenchmark
  # A fetcher based on patron
  class Fetcher
    attr_accessor :url, :start, :stop, :result, :body

    def initialize(url)
      @url = url
      @session = Patron::Session.new
      @session = Patron::Session.new
      @session.timeout = 20
      @session.headers['User-Agent'] = "Web-Benchmark/#{WebBenchmark::VERSION}"
    end

    def fetch
      @start  = Time.now
      @result = get @url
      @stop   = Time.now

      if @result.status == 200
        @body = Nokogiri::HTML(@result.body)
      end

      return @result.status < 400 ? true : false

    rescue Exception, Timeout::Error => ex
      $stderr.puts ex.message
      return false

    end

    def get(uri)
      @session.get uri
    end

    def fetch_assets(cached)
      return [] if @body.nil?

      start = Time.now
      fetched = []
      @body.css("img").each do |img|
        next if cached.include? img[:src]

        get img[:src]
        fetched << img[:src]
      end

      @body.css("script").each do |script|
        next if script[:src].nil? or script[:src] == ""
        next if cached.include? script[:src]

        get script[:src]
        fetched << script[:src]
      end

      @body.css("link").each do |link|
        next if link[:href].nil? or link[:href] == ""
        next if cached.include? link[:href]

        get link[:href]
        fetched << link[:href]
      end

      @stop += (Time.now - start)

      return fetched
    end

  end
end