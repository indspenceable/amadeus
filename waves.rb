module Waves
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

  def noise(t)
    @noise ||= {}
    @noise[t.to_i % Samplerate] ||= (rand*2)-1
  end
end
