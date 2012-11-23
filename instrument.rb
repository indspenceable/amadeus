class Instrument
  DEGREES = {
    1 => 0,
    2 => 2,
    3 => 4,
    4 => 5,
    5 => 7,
    6 => 9,
    7 => 11
  }
  def initialize tracker, scale_frquency, quarter_length, wave
    @quarter_length = quarter_length
    @root = scale_frquency
    #@wave = wave.is_a?(Symbol) ? ->(t) { self.send(wave) } : wave
    @wave = :sin
    @amplitude = 1.0
    @degrees = DEGREES

    @tracker = tracker
  end
  def chord(notes_and_opts, duration)
    notes_and_opts.each do |args|
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
    # figure out how many half steps up from the root we are
    half_steps = @degrees[degree]
    half_steps += opts[:sharp] if opts[:sharp]
    half_steps -= opts[:flat] if opts[:flat]

    frequency = @root * (SHARP**half_steps)
    frequency /= ((opts[:down] || 0) + 1)
    frequency *= ((opts[:up] || 0) + 1)

    amplitude = opts[:amplitude] || @amplitude

    tracker = opts[:tracker] || @tracker

    tracker.beep(@wave, frequency, amplitude, duration*@quarter_length)
  end
  def rest duration
    @tracker.rest(duration*@quarter_length)
  end
end

if __FILE__ == $0
  require './amadeus'
  Amadeus.play do |a|
    i = Instrument.new(a, NOTES[:c][3], 4, :sin)
    4.times do
      i.chord([1,3,5],4)
      i.chord([[1, flat:1], 2, 5], 4)
      i.chord([1,4,6],4)
      i.chord([1,3,5],2)
      i.chord([[1, flat:1], 2, 5], 2)
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
