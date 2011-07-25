require './lib/statistics'

# monkey path the Time class to easily identify concurrent requests
class Time
  def before?(other)
    self < other
  end

  def after?(other)
    self > other
  end
end

class WebBenchmark
  class Interpretor
    attr_accessor :sets

    def initialize(set=nil)
      set = WebBenchmark::Results.get_all if set.nil?

      @sets = []
      @sets << set unless set == false
    end

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
      info[:std_dev]    = Statistics.standard_deviation(info[:durations])
      info[:sample]     = requests.count
      info[:concurrent] = info.delete(:conc).count

      return info
    end

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
          res[:slower] = 100 - ((base[:mean] / res[:mean]) * 100)
        end
      end

      results
    end

  end
end