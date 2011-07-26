require './lib/statistics'

# monkey path the Time class to easily identify concurrent requests
class Time
  # is the other time before this time (in hundreds of seconds)
  def before?(other)
    self.hsec < other.hsec
  end

  # is the other time after this time (in hundreds of seconds)
  def after?(other)
    self.hsec > other.hsec
  end

  # time in hundreds of seconds
  def hsec
    (self.to_f * 100).to_i
  end
end

class WebBenchmark

  # A results interpretor - not really...
  class Interpretor
    attr_accessor :sets

    def initialize(set=nil)
      set = WebBenchmark::Results.get_all if set.nil?

      @sets = []
      @sets << set unless set == false
    end

    # Interpret a Results set
    #
    # Find total request time, mean, standard deviation, sample size and the
    # number of concurrent requests. Requests are considered concurring when
    # they overlap (R1 starts before R2 and ends before R2 ends, making R2 the
    # concurrent request)
    #
    def interpret(set=@sets.first)
      info = {
        :total      => 0,
        :durations  => [],
        :conc       => [],
        :mean       => 0,
        :std_dev    => 0,
        :sample     => 0,
        :concurrent => 0,
      }

      requests = set.collect { |url, results| results.times }.flatten

      requests.each do |request|
        time  = request[:stop] - request[:start]

        info[:total]     += time
        info[:durations] << time

        (requests - info[:conc] - [request]).each do |other|
          if ( other[:start].after?(request[:start]) and
               other[:start].before?(request[:stop])
          )
            info[:conc] << other
          end
        end
      end

      info[:mean]       = Statistics.mean(info[:durations])
      info[:min]        = Statistics.floor(info[:durations])
      info[:max]        = Statistics.ceiling(info[:durations])
      info[:std_dev]    = Statistics.standard_deviation(info[:durations])
      info[:sample]     = requests.count
      info[:concurrent] = info.delete(:conc).count

      return info
    end

    # #interpret all defineded sets. Assume the first set is the base line and
    # calculate the % slower for each later set. Return the interpreted Results
    #
    def compare
      results = []
      @sets.each do |set|
        results << interpret(set)
      end

      base = nil
      results.each do |res|
        if base.nil?
          base = res
          base[:slower] = 0
        else
          res[:slower] = ((res[:mean] / base[:mean]) * 100) - 100
        end
      end

      results
    end

    def urls
      @sets.collect(&:url)
    end
  end
end