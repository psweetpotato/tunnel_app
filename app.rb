require 'sinatra/base'
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

  TWIT_CONSUMER_KEY = "CVTaMkEx6rKwhm5x2hSjRERau"
  TWIT_CONSUMER_SECRET = "xycELG4QVvRPdP1dHMugeXUgmAmODE3CekS7VPD4Jk1MIhDYXf"
  TWIT_OWNER_ID = "2699174835"
  TWIT_ACCESS_TOKEN = "2699174835-zejsRftMeSZnTL6MGMW4PvbMoWvuHNh0UeUvgws"
  TWIT_ACCESS_SECRET = "k2wzFh0LJy4zxaUPdPQhJ5mXkNrGug8jqBk7W2QgXv8CL"
  WU_KEY = ENV["4dd8a202d9e3383b"]
  YORK_SEARCH_KEY = "89b8034ef450f0c931fa447d7dca0d8d:1:69766109"
  INSTA_CLIENT_KEY= "64116f06f3ae4b13abb5a26e2fc84a43"
  INSTA_CLIENT_SECRET = "507673b069c64e04a16f2d4078311e16"



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
  before('/profile') do
    params = {:twitter_toggle => "true",
              :times_toggle => "true",
              :graph_toggle => "true",
              :weather_toggle => false
            }
    session[:twitter_toggle] = params[:twitter_toggle]
    session[:times_toggle] = params[:times_toggle]
    session[:graph_toggle] = params[:graph_toggle]
    session[:weather_toggle] = params[:weather_toggle]
  end

  get('/') do
    render(:erb, :index)
  end

  get('/profile') do
    render(:erb, :profile)
  end

  get('/profile/retry')do
    @obscure = true
    render(:erb, :profile)
  end

  get('/profile/edit') do
    render(:erb, :edit)
  end

  get('/feeds/id') do
    @feed_index = params[:id]
    render(:erb, :feed_id)
  end

  get('/feeds') do
    if params[:obsession]
    session[:obsession] = params[:obsession].capitalize
    end
    # FIXME hardcoded until peristing data works
    #### TIMES #####
    if session[:times_toggle] == "true"
      @base_url = "http://api.nytimes.com/svc/search/v2/articlesearch.json?"
      @times_url = "#{@base_url}fq=#{session[:obsession]}&api-key=#{YORK_SEARCH_KEY}"
      begin
        times_response = HTTParty.get("#{@times_url}").to_json
        session[:times_article_url] = JSON.parse(times_response)["response"]["docs"][0]["web_url"]
        session[:times_snippet] = JSON.parse(times_response)["response"]["docs"][0]["snippet"]
        session[:times_headline] = JSON.parse(times_response)["response"]["docs"][0]["headline"]["main"]
      rescue
        redirect to('/profile/retry')
      end
    end
    ### TWITTER ####
    if session[:twitter_toggle] == "true"
      session[:tweets] = []
        TWIT_CLIENT.search("#{session[:obsession]}", :result_type => "recent").take(5).each_with_index do |tweet, index|
        @name = tweet.user.screen_name
        @text = tweet.text
        session[:tweets].push("#{@name} says: '#{@text}'")
        end
    end
    if session[:weather_toggle] == "true"
      raw_url = "http://api.wunderground.com/api/4dd8a202d9e3383b/conditions/q/#{session[:state]}/#{session[:city]}.json"
      encoded_url = URI.encode(raw_url)
      @weather_url = URI.parse(encoded_url)
      HTTParty.get(@weather_url) do |f|
        json_string = f.read.to_json
        parsed_json = JSON.parse(json_string)
        location = parsed_json['state']['city']
        temp_f = parsed_json['current_observation']['temp_f']
        print "Current temperature in #{location} is: #{temp_f}\n"
      end
    end
    render(:erb, :'/Feeds/feeds')
  end

  get('/feeds/twitter') do
    render(:erb, :'/Feeds/feed_twitter')
  end

  get('/feeds/times') do
    render(:erb, :'/Feeds/feed_times')
  end

  get('/feeds/graph') do
    render(:erb, :'/Feeds/feed_graph')
  end

###############
#    POST     #
###############
  post('/feeds') do
    if params[:twitter_toggle] == nil
      session[:twitter_toggle] = false
    else
      session[:twitter_toggle] = "true"
    end
    if params[:times_toggle] == nil
      session[:times_toggle] = false
    else
      session[:times_toggle] = "true"
    end
    if params[:graph_toggle] == nil
      session[:graph_toggle] = false
    else
      session[:graph_toggle] = "true"
    end
    if params[:weather_toggle] == nil
      session[:weather_toggle] = false
    else
      session[:weather_toggle] = "true"
    end

    session[:city] = params[:city]
    session[:state] = params[:state]
    redirect to('/feeds')
  end

    ######### INSTA #######
    # CALLBACK_URL = "http://127.0.0.1:9292/callback_uri"

    # Instagram.configure do |config|
    #   config.client_id = INSTA_CLIENT_KEY
    #   config.client_secret = INSTA_CLIENT_SECRET
    # end


  # get('/callback_uri') do
  #   hub_challenge_param = "15f7d1a91c1f40f8a748fd134752feb3"
  # end

  # post('/insta') do
  #   curl -F 'client_id=#{INSTA_CLIENT_KEY}' \
  #    -F 'client_secret=#{INSTA_CLIENT_SECRET}' \
  #    -F 'object=tag' \
  #    -F 'aspect=media' \
  #    -F 'verify_token=myVerifyToken' \
  #    -F 'object_id=#{@obsession}' \
  #    -F 'callback_url=http://127.0.0.1:9292/callback_uri' \
  #    https://api.instagram.com/v1/subscriptions/

  # end
end
