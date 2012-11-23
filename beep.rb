Samplerate = 8000
NORMALIZE_RATE = 8.0
NOTES = Hash.new(){|h,k| h[k] = {}}

module Player
  def self.track
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
  # 2) Eval the block in the context of the instance of Player

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
      # def method_missing(msg, *args)
      #   if OPTIONS.include?(msg)
      #     NoteBuilder.new(@track, @options.merge({msg => args.first}))
      #   else
      #     super
      #   end
      # end
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

def intro(t)
  e = t.sound.wave_type(:square).duration(2).frequency(NOTES[:e][4]).amplitude(1.0)
  c = e.frequency(NOTES[:c][4])
  g = e.frequency(NOTES[:g][4])
  gs= e.frequency(NOTES[:g][3])

  2.times {
    e.play
  }

  t.rest(2)

  e.play
  t.rest(2)

  c.play

  e.play
  t.rest(2)

  g.play
  t.rest(6)

  t.split do |t2|
    e.frequency(NOTES[:b][3]).play(t2)
  end.split do |t2|
    e.frequency(NOTES[:d][4]).play(t2)
  end
  gs.amplitude(1.5).play
  t.rest(6)
end
def verse(t)
  e2 = t.sound.wave_type(:square).duration(2).frequency(NOTES[:e][4]).amplitude(1.0)
  c2 = e2.frequency(NOTES[:c][4])
  g2 = e2.frequency(NOTES[:g][4])

  c1 = e2.frequency(NOTES[:c][4])
  e1 = e2.frequency(NOTES[:e][3])
  g1 = e2.frequency(NOTES[:g][3])
  a1 = g1.sharp.sharp

  c2.play
  t.rest(4)
  g1.play
  t.rest(4)
  e1.play
  t.rest(4)

  a1.play
  t.rest(2)
  a1.sharp.sharp.play
  t.rest(2)
  a1.sharp.play
  t.rest(2)
  a1.play
  g1.play
  c2.play
  t.rest(2)
  e2.play
  g2.play
  t.rest(2)
  e2.play
  e2.sharp.play
  t.rest(2)
  e2.play
  t.rest(2)

  c2.play
  t.rest(2)
  c2.sharp.sharp.play
  c2.flat.play
  t.rest(2)
end

def bridge_background(t)
  e1 = t.sound.wave_type(:square).duration(2).frequency(NOTES[:e][2]).amplitude(1.0)
  c1 = e1.frequency(NOTES[:c][2])
  g1 = e1.frequency(NOTES[:g][2])

  f1 = e1.sharp
  a1 = g1.sharp.sharp
  c2 = e1.frequency(NOTES[:c][3])

  c_riff = ->() {
    c1.play
    t.rest(4)

    e1.play
    t.rest(4)

    g1.play
    t.rest(2)
  }
  #---
  f_riff = ->() {
    f1.play
    t.rest(4)

    a1.play
    t.rest(4)

    c2.play
    t.rest(2)
  }
  #---
  c_riff.call
  f_riff.call
  c_riff.call

  t.rest(2)
  g1.play
  t.rest(2)
  g1.play
  g1.play
  t.rest(2)
  e1.frequency(NOTES[:g][1]).play
  t.rest(2)

  c_riff.call
  f_riff.call

  t.rest(4)
  a1.play
  t.rest(4)
  a1.sharp.play
  t.rest(4)
  c2.play
  t.rest(4)
  g1.play
  g1.play
  t.rest(2)
  c1.play
  t.rest(2)
end

def bridge_melody(t)
  e2 = t.sound.wave_type(:square).duration(2).frequency(NOTES[:e][4]).amplitude(1.0)
  c2 = e2.frequency(NOTES[:c][4])
  g2 = e2.frequency(NOTES[:g][4])

  c1 = e2.frequency(NOTES[:c][4])
  e1 = e2.frequency(NOTES[:e][3])
  g1 = e2.frequency(NOTES[:g][3])
  a1 = g1.sharp.sharp

  first_riff = ->() {
    t.rest(4)
    g2.play
    g2.flat.play
    g2.flat.flat.play
    e2.flat.play
    t.rest(2)
    e2.play
    t.rest(2)
  }
  second_riff = ->() {
    g1.play
    g1.sharp.sharp.play
    c2.play
    t.rest(2)
    g1.sharp.sharp.play
    c2.play
    c2.sharp.sharp.play
  }

  first_riff.call
  second_riff.call

  first_riff.call
  c2.play
  t.rest(2)
  c2.play
  c2.play
  t.rest(6)

  first_riff.call
  second_riff.call

  t.rest(4)
  t.split do |t2|
    g2.play(t2)
  end
  e2.flat.play
  t.rest(4)
  t.split do |t2|
    g2.flat.flat.play(t2)
  end
  c2.sharp.sharp.play
  t.rest(4)
  t.split do |t2|
    e2.play(t2)
  end
  c2.play
end

def bridge(t)
  t.split do |t2|
    bridge_melody(t2)
  end
  bridge_background(t)
end

Player.track do |t|
  intro(t)
  2.times { verse(t) }
  2.times { bridge(t) }
end
