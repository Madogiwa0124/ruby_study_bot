require 'date'
require 'twitter'
require 'dotenv/load'
require_relative 'ruby_manual.rb'
require_relative 'ruby_magazine.rb'

class Tweet
    # clientとtimelineは公開
    attr_accessor :client
  def initialize
    # 投稿内容の初期化
    @text = ""
    # クライアントの生成
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end
  end

  # Tweetの投稿処理呼び出し
  def send_tweet
    create_text
    update
  end

  # ツイート本文の生成
  def create_text
    if DateTime.now.hour == 7
      # AM7:00は、曜日毎のメッセージを投稿
      # 投稿を1時間毎から変更する場合は条件を修正する必要あり
      create_week_text
    elsif DateTime.now.hour == 8
      # AM8:00は、るびまのバックナンバーを投稿
      # 投稿を1時間毎から変更する場合は条件を修正する必要あり
      create_ruby_magazine_text
    else
      # クラス、メソッド、リファレンスマニュアルのページを投稿
      create_class_method_text
    end
  end

  private

  # るびまのバックナンバーのタイトルとURLを生成
  def create_ruby_magazine_text
    ruby_magazine = RubyMagazine.new
    ruby_magazine = ruby_magazine.get_magazine_page
    @text = <<-END
    本日のるびま(RubyistMagazine)のバックナンバーですφ(..)
    タイトル:#{ruby_magazine[:title]}
    URL:#{ruby_magazine[:url]}
    END
  end

  # クラスとメソッド、rubyリファレンスマニュアルへのリンクを生成
  def create_class_method_text
    ruby_manual = RubyReferenceManual.new
    # 主要クラスから対象となるクラスをランダムに抽出
    target_class = ruby_manual.class_list.sample
    # 対象クラスから基底クラスのメソッド以外を抽出
    method = ruby_manual.method_list(target_class).sample
    # メソッドへのリンクにしようされているIDを生成
    id = url_encode_text(method.to_s.upcase)
    id = "#I_#{id}"
    # 投稿内容の作成
    @text = <<-END
    rubyのメソッド、調べて勉強φ(..)！(ver#{ RubyReferenceManual::RUBY_VERSION })
    Class  : #{ target_class }
    Method : #{ method }
    Manual :#{RubyReferenceManual::MANUAL_URL}#{target_class}.html#{id}
    END
  end

  def url_encode_text(text)
    text
    .gsub('?','--3F')
    .gsub('=','--3D')
    .gsub('<','--3C')
    .gsub('>','--3E')
    .gsub('!','--21')
    .gsub('%','--25')
    .gsub('@','--40')
    .gsub('[','--5b')
    .gsub(']','--5d')
    .gsub('~','--7e')
    .gsub('*','--2a')
    .gsub('+','--2b')
  end

  # 曜日毎のメッセージを設定
  def create_week_text
    week = Date.today.wday
    @text = case week
    when 0 then "にっこりにちようび〜、週の終わりまで勉強がんばってえらい！(o・ω・o)"
    when 1 then "げつげつげつようび〜、週初めから勉強頑張ってえらい！(o・ω・o)"
    when 2 then "かっかっかようび〜、やる気も燃え上がるー(｀・ω・´)！"
    when 3 then "すいすいすいようび〜、勉強もすいすい進むよ〜(・ω・ 　⊃ 　)⊃≡"
    when 4 then "もくもくもくようび〜、もくもく勉強だー！φ(..)"
    when 5 then "きんきんきんようび〜、明日から休み、がんばろー(/･ω･)/"
    when 6 then "どっどっどようび〜、どんどん勉強を進めていこーφ(..)"
    end
  end

  # Tweet投稿処理
  def update
    begin
      @client.update(@text)
    rescue => e
      p e # エラー時はログを出力
    end
  end
end

# ツイートを実行
if __FILE__ == $0
  Tweet.new.send_tweet
end
