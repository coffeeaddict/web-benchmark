class WebBenchmark

  # A results class, keeps score per URL with a Singleton pattern
  class Results

    # remove all the singleton instances
    def self.clear
      @@instances = {}
    end

    # return a list of all the singleton instances
    def self.instances
      @@instances ||= {}
    end

    # get a copy of all the instances (for later interpretation, etc)
    def self.get_all
      @@instances.dup
    rescue
      {}
    end

    # get or create an instance for the given URL
    def self.instance(url)
      if instances.has_key?(url)
        return instances[url]
      else
        instances[url] = new(url)
      end
    end

    attr_accessor :url, :times
    def initialize(url)
      @url   = url
      @times = []
    end

    # record time and status information for the current URL instance
    def record(start, stop, status)
      @times << {
        :start  => start,
        :stop   => stop,
        :status => status}
    end

    private_class_method :new, :instances
  end
end