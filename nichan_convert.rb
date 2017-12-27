require "kconv"
require "pathname"
require "open-uri"
require "natto"

nm = Natto::MeCab.new('-F%m\t%f[0]\t%f[7]')
Pathname("2ch棋譜_名前.source.txt").readlines.each do |e|
  e = e.strip
  if e.match?(/\p{Han}/) && !e.match?(/\p{ASCII}/)
    begin
      yomi_list = []
      enum = nm.enum_parse(e)
      enum.each do |e|
        if e.is_eos?
          break
        end
        kanji, syurui, yomi = e.feature.split(/\t/)
        yomi = NKF.nkf("-w --hiragana", yomi)
        yomi_list << yomi
      end
      puts "#{yomi_list.join} #{e}"
    rescue Natto::MeCabError
      puts "#？ #{e}"
    end
  end
end
