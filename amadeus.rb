Samplerate = 8000
NORMALIZE_RATE = 8.0
NOTES = Hash.new(){|h,k| h[k] = {}}

module Amadeus
  def self.play
    data = Hash.new(0)
    locks = []
    t = Track.new(0, data, locks)

    yield t

    until locks.empty?
      sleep(0.1)
    end

    output = (0..data.keys.sort.last).to_a.map do |i|
      data[i].to_i.+(127).chr
    end.join

    STDOUT << output
    STDOUT.flush
  end
  # TODO
  # 1) add method missing that turns a3 => NOTES[a][3]
  # 2) Eval the block in the context of the instance of Amadeus

  private

  class Track
    def initialize offset, store, locks
      @data = store
      @offset = offset
      @locks = locks
    end

    def split
      @locks << true
      offset = @offset
      Thread.new do
        yield Track.new(offset, @data, @locks)
        @locks.pop
      end
      self
    end

    def slide(meth, start_frequency, end_frequency, amplitude, duration)
      steps = duration * Samplerate

      steps.times do |s|
        t = s*((1.0/Samplerate) - duration)/steps
        frequency = start_frequency + s*(end_frequency - start_frequency)/steps.to_f
        y = send(meth, t * frequency)*amplitude * 50 / NORMALIZE_RATE;
        @data[@offset] += y
        @offset += 1
      end
    end
    def beep(meth, frequency, amplitude, duration)
      slide(meth, frequency, frequency, amplitude, duration)
    end
    def rest(duration)
      @offset += duration * Samplerate
    end

    def sound()
      NoteBuilder.new(self, {})
    end
    private

    class NoteBuilder
      OPTIONS = [:wave_type, :frequency, :duration, :amplitude]
      def initialize(track, options)
        @track = track
        @options = options
        @cache = Hash.new(){|h,k| h[k] = {}}
      end
      def sharp
        @sharp ||= NoteBuilder.new(@track, @options.merge({frequency: @options[:frequency]*SHARP}))
      end
      def flat
        @flat ||= NoteBuilder.new(@track, @options.merge({frequency: @options[:frequency]/SHARP}))
      end
      OPTIONS.each do |msg|
        define_method(msg) do |arg|
          @cache[msg][arg] ||= NoteBuilder.new(@track, @options.merge({msg => arg}))
        end
      end

      def play(track=nil)
        unless (OPTIONS-@options.keys).empty?
          raise "You didn't set: #{(OPTIONS-@options.keys).inspect}"
        end
        (track||@track).beep(@options[:wave_type], @options[:frequency], @options[:amplitude], @options[:duration])
      end
    end

    def sin(t)
      Math.sin(t)
    end
    def saw(t)
        a = Math::PI
        ta = t/a
        2*(ta - (0.5 + ta).floor)
    end

    def square(t)
      st = Math.sin(t)
      return 0 if st == 0
      st/st.abs
    end
  end
end

SHARP = 1.059
NOTES[:a][4] = 440
prev = 440/1.059
# fill in all the notes on octive 4
'a as b c cs d ds e f fs g gs'.split(' ').each do |c|
  new_val = prev*SHARP
  #Notes.const_set(c.upcase.to_sym, new_val)
  NOTES[c.to_sym][4] ||= new_val
  prev = new_val
end
[3,2,1,4,5,6].each do |i|
  NOTES.keys.each do |k|
    NOTES[k][i] = NOTES[k][4] * (2 ** (i-4))
  end
end
