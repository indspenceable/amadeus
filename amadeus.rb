require './waves'

Samplerate = 44100
NOTES = Hash.new(){|h,k| h[k] = {}}

module Amadeus
  def self.play(opts={})
    bleeps = []
    t = Track.new(0, bleeps)

    yield t


    bleeps.sort!{|a,b| a.starting_time <=> b.starting_time}
    last_ending = bleeps.max do |a,b|
      a.starting_time + a.duration <=> b.starting_time + b.duration
    end
    ending_time = last_ending.starting_time + last_ending.duration

    active_sounds = []
    output = ending_time.to_i.times.map do |i|
      #drop all that aren't active anymore
      active_sounds.select!{|s| s.active_at?(i)}
      # add all sounds that will be active, as of now
      while bleeps[0] && bleeps[0].active_at?(i)
        active_sounds << bleeps.shift
      end
      # compute produced char by summing all frequencies, then converting
      #chr = active_sounds.map{|s| s.frequency_at(i)}.inject(&:+).to_i.+(127).chr

      active_sounds.map{|s| s.frequency_at(i)}.inject(&:+).to_i.+(127).chr
    end.join

    # puts output.length
    # exit

    case opts[:output]
    when :sox
      IO.popen("sox -traw -r44100 -b8 -e unsigned-integer - -tcoreaudio", "w") do |io|
        io << output
      end
    when :magick
      require 'RMagick'
      image_sampling_period = Samplerate/(opts[:samplerate] || 1000)

      image = Magick::Image.new(ending_time/image_sampling_period + 1, 256)
      #skip the first and last
      ary = output.split("")
      ary[0] = nil
      ary[-1] = nil
      ary[-2] = nil
      ary.each_with_index do |c, n|
        next unless c
        next unless n%image_sampling_period == 0
        num = c.ord
        x = n/image_sampling_period
        image.view(x, num, 1, 1) do |view|
          view[][] = Magick::Pixel.new(0, Magick::MaxRGB)
        end
      end
      filename = opts[:file_name] || "out.gif"
      puts "Preparing to write to #{filename}"
      image.write(filename)
    else
      STDOUT << output
      STDOUT.flush
    end
  end
  # TODO
  # 1) add method missing that turns a3 => NOTES[a][3]
  # 2) Eval the block in the context of the instance of Amadeus

  private
  class Beep < Struct.new(:starting_time,
    :oscillator, :start_frequency, :end_frequency, :amplitude, :duration)
    def active_at?(t)
      t >= starting_time && t <= (starting_time+duration)
    end
    def frequency_at(t)
      time_units_passed = t.to_f - starting_time
      frequency = 2 **(
        (time_units_passed / duration) *(Math.log2(end_frequency) -
          Math.log2(start_frequency)) + Math.log2(start_frequency))
      oscillator.call(time_units_passed*2*(Math::PI/Samplerate)*frequency)*amplitude/8*127;
    end
  end

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
      @data << Beep.new(@offset, lam, start_frequency, end_frequency, amplitude, duration*Samplerate)
      #now sleep for the duration
      rest(duration)
    end
    def depricated
      if wave_method.is_a?(Symbol)
        lam = ->(i) { self.send(wave_method, i) }
      else
        lam = wave_method
      end

      steps = duration * Samplerate

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
