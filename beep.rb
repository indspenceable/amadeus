Samplerate = 8000
NORMALIZE_RATE = 4
NOTES = Hash.new(){|h,k| h[k] = {}}

TRACK = []
TEST = (ARGV[0] == "test")

module Player
  def self.track

    data = Hash.new(){|h,k| h[k] = []}
    t = Track.new(0, data)
    yield t
    output = ""
    0.upto(data.keys.sort.last).each do |i|
      output << data[i].inject(0, &:+).to_i./(NORMALIZE_RATE).chr
    end
    unless TEST
      STDOUT << output
      STDOUT.flush
    end
  end

  private

  class Track
    def initialize offset, store
      @data = store
      @offset = offset
    end

    def split
      yield Track.new(@offset, @data)
    end

    def slide(meth, start_frequency, end_frequency, amplitude, duration)
      steps = duration * Samplerate

      steps.times do |s|
        t = s*((1.0/Samplerate) - duration)/steps
        frequency = start_frequency + s*(end_frequency - start_frequency)/steps.to_f
        y = send(meth, t * frequency)*amplitude * 50 + 127;
        @data[@offset] << y
        @offset += 1
      end
    end
    def beep(meth, frequency, amplitude, duration)
      slide(meth, frequency, frequency, amplitude, duration)
    end
    def rest(duration)
      beep(:sin, 0,0, duration)
    end

    def sound()
      NoteBuilder.new(self, {})
    end
    private

    class NoteBuilder
      OPTIONS = [:wave_type, :frequency, :duration]
      def initialize(track, options)
        @track = track
        @options = options
      end
      def method_missing(msg, *args)
        if OPTIONS.include?(msg)
          NoteBuilder.new(@track, @options.merge({msg => args.first}))
        else
          super
        end
      end
      def play(track=nil)
        unless (OPTIONS-@options.keys).empty?
          raise "You didn't set: #{(OPTIONS-@options.keys).inspect}"
        end
        (track||@track).beep(@options[:wave_type], @options[:frequency], 1.0, @options[:duration])
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
      return 1 if st == 0
      st/st.abs
    end
  end
end


NOTES[:a][4] = 440
prev = 440/1.059
# fill in all the notes on octive 4
'a as b c cs d ds e f fs g gs'.split(' ').each do |c|
  new_val = prev*1.059
  #Notes.const_set(c.upcase.to_sym, new_val)
  NOTES[c.to_sym][4] ||= new_val
  prev = new_val
end
[3,2,1,4,5,6].each do |i|
  NOTES.keys.each do |k|
    NOTES[k][i] = NOTES[k][4] * (2 ** (i-4))
  end
end


Player.track do |t|
  e = t.sound.wave_type(:sin).duration(1).frequency(NOTES[:e][4])
  c = e.frequency(NOTES[:c][4])
  g = e.frequency(NOTES[:g][4])
  gs= e.frequency(NOTES[:g][3])

  2.times {
    e.play
    t.rest(1)
  }

  t.rest(2)

  e.play
  t.rest(3)

  c.play
  t.rest(1)

  e.play
  t.rest(3)

  g.play
  t.rest(8)

  t.split do |t2|
    e.frequency(NOTES[:b][3]).play(t2)
  end
  t.split do |t2|
    e.frequency(NOTES[:d][4]).play(t2)
  end

  gs.play
  t.rest(8)


end
