require 'sinatra/base'
require 'securerandom'
require 'httparty'
require 'instagram'
require 'twitter'
require 'redis'
require 'json'
require 'pry'


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
  WU_KEY = "611266f891f71333"
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
            }
    TWITTER_TOGGLE = params[:twitter_toggle]
    TIMES_TOGGLE = params[:times_toggle]
    GRAPH_TOGGLE = params[:graph_toggle]
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
    @obsession = "test"
    #params[:obsession].capitalize
    # FIXME hardcoded until peristing data works
    #### TIMES #####
    if TIMES_TOGGLE == "true"
      @base_url = "http://api.nytimes.com/svc/search/v2/articlesearch.json?"
      @times_url = "#{@base_url}fq=#{@obsession}&api-key=#{YORK_SEARCH_KEY}"
      begin
        times_response = HTTParty.get("#{@times_url}").to_json
        @times_article_url = JSON.parse(times_response)["response"]["docs"][0]["web_url"]
        @times_snippet = JSON.parse(times_response)["response"]["docs"][0]["snippet"]
        @times_headline = JSON.parse(times_response)["response"]["docs"][0]["headline"]["main"]
      rescue
        redirect to('/profile/retry')
      end
    end
    ### TWITTER ####
    if TWITTER_TOGGLE == "true"
      @tweets = []
        TWIT_CLIENT.search("#{@obsession}", :result_type => "recent").take(5).each_with_index do |tweet, index|
        @name = tweet.user.screen_name
        @text = tweet.text
        @tweets.push("#{@name} says: '#{@text}'")
        end
    end
    render(:erb, :feeds)
  end

  get('/feeds/twitter') do
    @obsession = "test"
    #params[:obsession].capitalize
    # FIXME hardcoded until peristing data works
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
      TWITTER_TOGGLE = false
    else
      TWITTER_TOGGLE = "true"
    end
    if params[:times_toggle] == nil
      TIMES_TOGGLE = false
    else
      TIMES_TOGGLE = "true"
    end
    if params[:graph_toggle] == nil
      GRAPH_TOGGLE = false
    else
      GRAPH_TOGGLE = "true"
    end
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
