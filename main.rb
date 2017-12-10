require "kconv"
require "pathname"
require "open-uri"

shogi_vje_txt_url = "https://raw.githubusercontent.com/knu/imedic-shogi/master/shogi.vje.txt"

file = Pathname("shogi.vje.txt")

unless file.exist?
  file.write(open(shogi_vje_txt_url, &:read))
end

body = file.read.toutf8

out = []
out << ";; -*- coding: euc-jp-unix -*-"
out << ";; (skk-restart)"
out << ";;"
out << ";; okuri-ari entries."
out << ";; okuri-nasi entries."

body.lines.collect(&:strip).each do |line|
  next if line == ""
  if line.match(/^#/)
    out << ";; #{line}"
  else
    # "あい\t合\t【名サ】"
    yomi, kanji, syurui = line.split(/\t+/)
    if yomi.match?(/[[:digit:]]{2}/)
      p [:skip, yomi]
      next
    end
    yomi = yomi.tr("０-９", "0-9")
    out << "#{yomi} /#{kanji}/"
  end
end
str = out.join("\n") + "\n"
puts str
Pathname("SKK-JISYO.shogi.dic").write(str.toeuc)
