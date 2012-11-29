require './waves'

Samplerate = 44100
NOTES = Hash.new(){|h,k| h[k] = {}}

module Amadeus
  def self.play
    data = Hash.new(0)
    t = Track.new(0, data)

    yield t

    if data.any?
      output = (0..data.keys.sort.last).to_a.map do |i|
        data[i].to_i.+(127).chr
      end.join

      STDOUT << output
      STDOUT.flush
    end
  end
  # TODO
  # 1) add method missing that turns a3 => NOTES[a][3]
  # 2) Eval the block in the context of the instance of Amadeus

  private

  class Track
    def initialize offset, store
      @data = store
      @offset = offset
    end

    def split
      offset = @offset
      yield Track.new(offset, @data)
      self
    end

    def slide(wave_method, start_frequency, end_frequency, amplitude, duration)

      if wave_method.is_a?(Symbol)
        lam = ->(i) { self.send(wave_method, i) }
      else
        lam = wave_method
      end

      steps = duration * Samplerate
      raise "Bad duration! #{duration} #{steps}" if steps.to_i != steps

      steps.to_i.times do |s|
        frequency = start_frequency + (end_frequency - start_frequency)*s/steps.to_f
        y = lam.call(s*(Math::PI/Samplerate)*frequency)*amplitude/8*127;
        y.to_i.+(127).chr
        @data[@offset] += y
        @offset += 1
      end
    end
    def beep(meth, frequency, amplitude, duration)
      slide(meth, frequency, frequency, amplitude, duration)
    end
    def rest(duration)
      steps = duration * Samplerate
      raise "Bad duration! #{duration} #{steps}" if steps.to_i != steps
      @offset += steps.to_i
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
    include Waves
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
