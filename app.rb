require 'sinatra'
require 'securerandom'
require 'httparty'
require 'instagram'
require 'twitter'
require 'open-uri'
require 'redis'
require 'json'
require 'pry'
require 'uri'

class App < Sinatra::Base

  ########################
  # Configuration
  ########################

  configure do
    enable :logging
    enable :method_override
    enable :sessions
    set :session_secret, 'super secret'
    uri = URI.parse(ENV["REDISTOGO_URL"])
    $redis = Redis.new({:host => uri.host,
                        :port => uri.port,
                        :password => uri.password})
  end

  before do
    logger.info "Request Headers: #{headers}"
    logger.warn "Params: #{params}"
  end

  after do
    logger.info "Response Headers: #{response.headers}"
  end

  ########################
  #       API KEYS       #
  ########################

  TWIT_CONSUMER_KEY    = "CVTaMkEx6rKwhm5x2hSjRERau"
  TWIT_CONSUMER_SECRET = "xycELG4QVvRPdP1dHMugeXUgmAmODE3CekS7VPD4Jk1MIhDYXf"
  TWIT_OWNER_ID        = "2699174835"
  TWIT_ACCESS_TOKEN    = "2699174835-zejsRftMeSZnTL6MGMW4PvbMoWvuHNh0UeUvgws"
  TWIT_ACCESS_SECRET   = "k2wzFh0LJy4zxaUPdPQhJ5mXkNrGug8jqBk7W2QgXv8CL"
  WU_KEY               = ENV["4dd8a202d9e3383b"]
  YORK_SEARCH_KEY      = "89b8034ef450f0c931fa447d7dca0d8d:1:69766109"
  INSTA_CLIENT_KEY     = "64116f06f3ae4b13abb5a26e2fc84a43"
  INSTA_CLIENT_SECRET  = "507673b069c64e04a16f2d4078311e16"

  ########################
  #    Client Set Up     #
  ########################

  TWIT_CLIENT = Twitter::REST::Client.new do |config|
    config.consumer_key    = TWIT_CONSUMER_KEY
    config.consumer_secret = TWIT_CONSUMER_SECRET
    config.access_token        = TWIT_ACCESS_TOKEN
    config.access_token_secret = TWIT_ACCESS_SECRET
  end

  ########################
  # Routes
  ########################

  get('/') do
    redirect to('/profile')
  end

  get('/profile') do
    $redis.flushdb
    render(:erb, :profile)
  end

  get('/profile/retry')do
    @obscure = true
    render(:erb, :profile)
  end

  get('/profile/edit') do
    render(:erb, :profile)
  end

  get('/profile/logout') do
    @logged_out = true
    render(:erb, :profile)
  end

  get('/feeds/id') do
    @feed_index = params[:id]
    render(:erb, :feed_id)
  end

  get('/feeds') do
    # #### TIMES #####
    logger.info "beginning times"
    if $redis.exists("times_toggle")
      @base_url  = "http://api.nytimes.com/svc/search/v2/articlesearch.json?"
      @times_url = "#{@base_url}fq=headline.search:(#{$redis.get(:obsession)})&api-key=#{YORK_SEARCH_KEY}"
      begin
        times_response = HTTParty.get("#{@times_url}").to_json
        $redis.set(:times_article_url, JSON.parse(times_response)["response"]["docs"][0]["web_url"])
        $redis.set(:times_snippet,     JSON.parse(times_response)["response"]["docs"][0]["snippet"])
        $redis.set(:times_headline,    JSON.parse(times_response)["response"]["docs"][0]["headline"]["main"])
      rescue
        redirect to('/profile/retry')
      end
    end
    logger.info "end times"
    ### TWITTER ####
    logger.info "beginning twitter"
    @tweets = []
    if $redis.exists("twitter_toggle")
      # binding.pry
        TWIT_CLIENT.search("#{$redis.get(:obsession)}", :result_type => "recent").take(20).each_with_index do |tweet, index|
        @name = tweet.user.screen_name
        @text = tweet.text
        @tweets.push("#{@name} says: '#{@text}'")
        end
    end
    logger.info "end twitter"
    ### WEATHER ###
    logger.info "beginning weather"
    if $redis.exists("weather_toggle")
      @encoded_url = URI.encode("http://api.wunderground.com/api/4dd8a202d9e3383b/conditions/q/#{$redis.get[:state]}/#{$redis.get[:city]}.json")
      URI.parse(@encoded_url)
      open (@encoded_url) do |f|
      weather_string = f.read
      weather_parsed = JSON.parse(weather_string)
      $redis.set[:location] = weather_parsed['current_observation']['display_location']['full']
      $redis.set[:temp_f] = weather_parsed['current_observation']['temp_f']
      end
    end
    logger.info "end weather"
    render(:erb, :'feeds/feeds')
  end

  get('/feeds/twitter') do
    @tweets = []
    TWIT_CLIENT.search("#{$redis.get(:obsession)}", :result_type => "recent").take(20).each_with_index do |tweet, index|
        @name = tweet.user.screen_name
        @text = tweet.text
        @tweets.push("#{@name} says: '#{@text}'")
        end
    render(:erb, :'feeds/feed_twitter')
  end

  get('/feeds/times') do
    render(:erb, :'feeds/feed_times')
  end

  get('/feeds/graph') do
    render(:erb, :'feeds/feed_graph')
  end

  get('/logout') do
    #TODO
    redirect to ('/profile/logout')
  end

  ###############
  #    POST     #
  ###############
  post('/feeds') do
    $redis.set(:username, params[:username])
    $redis.set(:obsession, params[:obsession])
    $redis.set(:city, params[:city])
    $redis.set(:state, params[:state])
    if params["twitter_toggle"]
      $redis.set(:twitter_toggle, params["twitter_toggle"])
    end
    if params["times_toggle"]
      $redis.set(:times_toggle, params["times_toggle"])
    end
    if params["weather_toggle"]
      $redis.set(:weather_toggle, params["weather_toggle"])
    end
    if params["graph_toggle"]
      $redis.set(:graph_toggle, params["graph_toggle"])
    end
    redirect to('/feeds')
  end

end
