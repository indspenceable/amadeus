class Instrument
  def minor
    {
      1 => 0,
      2 => 2,
      3 => 3,
      4 => 5,
      # :b => 6,
      5 => 7,
      6 => 8,
      7 => 10
    }
  end
  def major
    {
      1 => 0,
      2 => 2,
      3 => 4,
      4 => 5,
      5 => 7,
      6 => 9,
      7 => 11
    }
  end
  def initialize tracker, scale_frquency, quarter_length, wave, amplitude, scale=:major
    @quarter_length = quarter_length
    @root = scale_frquency
    #@wave = wave.is_a?(Symbol) ? ->(t) { self.send(wave) } : wave
    @wave = wave
    @amplitude = amplitude
    @degrees = self.send(scale)

    @tracker = tracker
  end
  def rhythm(rhythm_string, degree, duration)
    rhythm_string.split('').each do |c|
      if c == '.'
        #this should probably just be two different methods for chords and notes
        if degree.is_a?(Array)
          chord(degree, duration)
        else
          play(degree, duration)
        end
      else
        rest(duration)
      end
    end
  end
  def chord(degrees_and_opts, duration)
    degrees_and_opts.each do |args|
      note, opts = nil, nil
      if args.is_a?(Array)
        note, opts = args
      else
        note = args
        opts = {}
      end
      @tracker.split do |t|
        play(note, duration, opts.merge({tracker: t}))
      end
    end
    rest(duration)
  end
  def play(degree, duration, opts={})
    opts = {opts => 1} if opts.is_a?(Symbol)

    octive = 0 + (opts[:up] || 0) - (opts[:down] || 0)
    while degree > 7
      degree -= 7
      octive += 1
    end
    while degree < 1
      degree += 7
      octive -= 1
    end

    # figure out how many half steps up from the root we are
    half_steps = @degrees[degree]
    half_steps += opts[:sharp] if opts[:sharp]
    half_steps -= opts[:flat] if opts[:flat]

    frequency = @root * (SHARP**half_steps)
    frequency *= (2**octive)

    amplitude = opts[:amplitude] || @amplitude

    tracker = opts[:tracker] || @tracker

    if opts[:slide_to]
      st = opts[:slide_to]
      st_degree = st[:degree]

      st_octive = 0 + (st[:up] || 0) - (st[:down] || 0)
      while st_degree > 7
        st_degree -= 7
        st_octive += 1
      end
      while st_degree < 1
        st_degree += 7
        st_octive -= 1
      end

      st_half_steps = @degrees[st_degree]
      st_half_steps += st[:sharp] if st[:sharp]
      st_half_steps -= st[:flat] if st[:flat]

      st_frequency = @root * (SHARP**st_half_steps)
      st_frequency /= ((st[:down] || 0) + 1)
      st_frequency *= ((st[:up] || 0) + 1)
    else
      st_frequency = frequency
    end

    tracker.slide(@wave, frequency, st_frequency, amplitude, duration*@quarter_length)
  end
  def rest duration
    @tracker.rest(duration*@quarter_length)
  end
end

class DetunedInstrument < Instrument
  def initialize detune_amount, tracker, scale_frquency, *args
    super(tracker, scale_frquency, *args)
    @detune_amount = detune_amount
  end
  def play degree, duration, opts={}
    opts = {opts => 1} if opts.is_a?(Symbol)
    orig = @root
    @root += @detune_amount
    (opts[:tracker] || @tracker).split do |t2|
      super(degree, duration, opts.merge({:tracker => t2}))
    end
    @root = orig
    super
  end
end

'.. . .  '

if __FILE__ == $0
  require './amadeus'
  Amadeus.play do |a|
    i = Instrument.new(a, NOTES[:c][3], 4, :sin)
    4.times do
      i.degree([1,3,5],4)
      i.degree([[1, flat:1], 2, 5], 4)
      i.degree([1,4,6],4)
      i.degree([1,3,5],2)
      i.degree([[1, flat:1], 2, 5], 2)
    end
    # [5, nil, 1, nil, 0.5, nil, 0.25, 0.2, 0.1].each_with_index do |d, n|
    #   next unless d
    #   (n+1).times do
    #     i = Instrument.new(a, NOTES[:c][3], d, :sin)
    #     i.play 6, 1, :down => 1
    #     i.play 1, 1
    #     i.play 3, 1
    #     i.play 5, 1
    #     i.play 7, 1
    #     i.play 2, 1, :up => 1
    #     i.play 1, 1, :up => 1
    #     i.play 5, 1, :up => 1
    #     i.play 3, 1, :up => 1
    #     i.play 1, 1, :up => 1
    #   end
    #   a.rest(3)
    # end
  end
end
