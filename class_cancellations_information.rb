require 'bundler'
Bundler.require

def here_document(contents,table_row)
  class_room = contents.css("div#portlet_acPortlet_0 tr:nth-of-type(#{table_row}) td:nth-of-type(3)").text
  teacher = contents.css("div#portlet_acPortlet_0 tr:nth-of-type(#{table_row}) td:nth-of-type(5)").text
  room = contents.css("div#portlet_acPortlet_0 tr:nth-of-type(#{table_row}) td:nth-of-type(6)").text
  text = <<-"EOS"

  #{class_room}
  #{teacher}
  #{room}
  EOS
  @str << text
end

def line_notify
  uri = URI.parse('https://notify-api.line.me/api/notify')
  request = Net::HTTP::Post.new(uri)

  request['Authorization'] = 'LINE Notifyのアクセストークンを入力'
  request.set_form_data(
      'message' => @str
  )
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end
end

def scraping
  today = Date.today.strftime('%Y-%m-%d')
  #スクレイピング処理
  agent = Mechanize.new
  agent.user_agent_alias = 'Mac Safari 4'
  agent.get('https://www.ac04.tamacc.chuo-u.ac.jp/ActiveCampus/sp/SPLogin.php') do |page|
    page.form_with(:action => '/ActiveCampus/sp/SPLogin.php') do |form|
      form.field_with(:name=>"login").value = '自分の学籍番号'
      form.field_with(:name=>"passwd").value = 'パスワード'
    end.submit
    page = agent.get('/ActiveCampus/sp/SPMenu.php?mode=action&mid=c6b2dda9f94ef88d').content.toutf8
    contents = Nokogiri::HTML.parse(page, nil, 'utf-8')
    @str = ''
    # 休講情報テーブルの行番号を設定
    table_row = 2
    date = contents.css('div#portlet_acPortlet_0 tr:nth-of-type(2) td:nth-of-type(2)').text
    while date == today
      if contents.css("div#portlet_acPortlet_0 tr:nth-of-type(#{table_row}) td:nth-of-type(4)").text == '商'
        here_document(contents,table_row)
      end
      table_row += 1
      date = contents.css("div#portlet_acPortlet_0 tr:nth-of-type(#{table_row}) td:nth-of-type(2)").text
    end
    line_notify()
  end
end

scraping()