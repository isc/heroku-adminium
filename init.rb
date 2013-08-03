class Heroku::Command::Adminium < Heroku::Command::Base
    
  def initialize(*args)
    super
    if respond_to? 'api'
      @config_vars = api.get_config_vars(app).body
    else
      @config_vars = heroku.config_vars(app)
    end
    @adminium_url = @config_vars["ADMINIUM_URL"]
    abort " !   Please add the adminium addon first." unless @adminium_url
    require 'rest_client'
  end

  def index
    puts "In order to provide you with an administration interface for your data,"
    puts "Adminium will store an encrypted version of the DATABASE_URL of your application"
    puts "(removing the addon will delete that info from the Adminium database)"
    puts "Do you confirm the plugin execution ? (yes / no)"
    print "> "
    answer = STDIN.gets
    if ['yes', 'y'].include? answer.chomp.downcase
      if db_urls.empty?
        puts "We did not find any DATABASE_URL for your application, please provide it manually on our add-on web page"
      else
        if db_urls.length > 1
          puts "We found several database urls you may want to connect to, please choose one :"
          db_urls.each_with_index { |db, index| puts "#{index + 1}. #{db[:key]} => #{db[:value]}" }
          begin
            answer = STDIN.gets
          end while answer.chomp.to_i <= 0 || answer.chomp.to_i > db_urls.length
          db_url_index = answer.chomp.to_i - 1
        else
          db_url_index = 0
        end
        RestClient::Resource.new(@adminium_url).put :account => {:db_url => db_urls[db_url_index][:value]}
        puts "Successfully enabled Adminium for the current app."
      end
    else
      puts "Plugin execution aborted."
    end
  end

  def db_urls
    return @db_urls unless @db_urls.nil?
    @db_urls = []
    ['DATABASE_URL', 'CLEARDB_DATABASE_URL', 'CLEARDB_DATABASE_URL_A', 'CLEARDB_DATABASE_URL_B', 'SHARED_DATABASE_URL'].each do |key|
      if @config_vars.has_key?(key) && !@db_urls.map{|d| d[:value]}.include?( @config_vars[key])
        @db_urls << {:key => key, :value => @config_vars[key]}
      end
    end
    @db_urls
  end

end
