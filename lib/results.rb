class WebBenchmark
  # a results class
  class Results
    def self.clear
      @@instances = {}
    end

    def self.instances
      @@instances ||= {}
    end

    def self.get_all
      @@instances.dup
    rescue
      {}
    end

    def self.instance(url)
      if instances.has_key?(url)
        return instances[url]
      else
        instances[url] = self.new(url)
      end
    end

    attr_accessor :url, :times
    def initialize(url)
      @url   = url
      @times = []
    end

    def record(start, stop, status)
      @times << {
        :start  => start,
        :stop   => stop,
        :status => status}
    end
  end
end