require "kconv"
require "pathname"
require "open-uri"
require "natto"

class App
  def run
    @out = []
    @out << ";; -*- coding: euc-jp-unix -*-"
    @out << ";; (skk-restart)"
    @out << ";;"
    @out << ";; okuri-ari entries."
    @out << ";; okuri-nasi entries."

    @rows = []

    shogi_vje_txt_import
    nichan_kifu_import

    @out += @rows

    str = @out.join("\n") + "\n"
    file = Pathname("SKK-JISYO.shogi.dic")
    file.write(str.toeuc)
    p @out.count
    puts file
  end

  def shogi_vje_txt_import
    shogi_vje_txt_url = "https://raw.githubusercontent.com/knu/imedic-shogi/master/shogi.vje.txt"

    file = Pathname("shogi.vje.txt")

    unless file.exist?
      file.write(open(shogi_vje_txt_url, &:read))
    end

    body = file.read.toutf8

    body.lines.collect(&:strip).each do |line|
      next if line == ""
      if line.match(/^#/)
        @out << ";; #{line}"
      else
        # "あい\t合\t【名サ】"
        yomi, kanji, syurui = line.split(/\t+/)

        # DDSKKの場合、将棋の座標の入力に特化した仕組みがあるため省く
        if yomi.match?(/[[:digit:]]{2}/)
          # p [:skip, yomi]
          next
        end

        yomi = yomi.tr("０-９", "0-9") # だいたいのSKKユーザーは全角数字を入力するのが難しいため

        @rows << "#{yomi} /#{kanji}/"
      end
    end
  end

  def nichan_kifu_import
    other = Pathname("2ch棋譜名前一覧_特殊.txt").readlines.inject({}) do |a, e|
      kanji, yomi = e.split(/\s+/)
      a.merge(kanji => yomi)
    end

    nm = Natto::MeCab.new('-F%m\t%f[0]\t%f[7]')
    Pathname("2ch棋譜名前一覧.txt").readlines.each do |e|
      e = e.strip
      if e.match?(/\p{ASCII}/)
      else
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
          # p [yomi_list.join, e]
          @rows << "#{yomi_list.join} /#{e}/"
        rescue Natto::MeCabError
          if yomi = other[e]
            p ["読み方補完", e, yomi]
            @rows << "#{yomi} /#{e}/"
          else
            @rows << ";; 読み方不明 /#{e}/ "
            p ["読み方不明", e]
          end
        end
      end
    end
  end
end

App.new.run
