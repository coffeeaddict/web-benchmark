# A helper with nice methods for statistics calculation
#
module Statistics
  def self.variance(population)
    n    = 0
    mean = 0.0
    s    = 0.0
    population.each { |x|
      n = n + 1
      delta = x - mean
      mean = mean + (delta / n)
      s = s + delta * (x - mean)
    }
    # if you want to calculate std deviation
    # of a sample change this to "s / (n-1)"
    res = s / (n-1)
    res = 0.0 if res.nan? or res.infinite?

    res
  end

  # calculate the standard deviation of a population
  # accepts: an array, the population
  # returns: the standard deviation
  def self.standard_deviation(population)
    Math.sqrt(self.variance(population))
  end

  def self.mean(population)
    mean = population.inject(0.0) { |s,r| s += r } / population.count
    mean = 0.0 if mean.nan? or mean.infinite?

    mean
  rescue
    0.0
  end

  def self.median(population)
    sorted = population.sort
    if population.count % 2 == 0
      return sorted[population.count / 2]
    else
      return mean(
        [sorted[population.count / 2], sorted[(population.count / 2) + 1]]
      )
    end
  end

  def self.floor(population)
    population.sort.first || 0.0
  end

  def self.ceiling(population)
    population.sort.last || 0.0
  end
end