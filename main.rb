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

    vje_import
    file_import("2ch棋譜_名前.txt")
    file_import("将棋ウォーズ系戦法.txt")
    file_import("その他.txt")

    @out += @rows.uniq

    str = @out.join("\n") + "\n"
    file = Pathname("SKK-JISYO.shogi.dic")
    file.write(str.toeuc)
    p @out.count
    puts file
  end

  def vje_import
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

  def file_import(file)
    Pathname(file).readlines.collect(&:strip).inject({}) do |a, e|
      next if e.empty?
      next if e.start_with?("#")
      yomi, kanji = e.split(/\s+/)
      @rows << "#{yomi} /#{kanji}/"
    end
  end
end

App.new.run
