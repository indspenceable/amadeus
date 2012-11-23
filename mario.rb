require './amadeus'

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
Amadeus.play do |t|
  intro(t)
  2.times { verse(t) }
  2.times { bridge(t) }
end
