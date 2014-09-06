require 'sinatra/base'
require 'securerandom'
require 'httparty'
require 'instagram'
require 'twitter'
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

  get('/') do
    render(:erb, :index)
  end

  get('/profile') do
    render(:erb, :profile)
  end

  get('/profile/edit') do
    render(:erb, :edit)
  end

  get('/feeds') do
    #TODO build classes for each feed
    @obsession = params[:obsession].capitalize

    #### TIMES ######
    @base_url = "http://api.nytimes.com/svc/search/v2/articlesearch.json?"
    @times_url = "#{@base_url}fq=#{@obsession}&api-key=#{YORK_SEARCH_KEY}"
    begin
      times_response = HTTParty.get("#{@times_url}").to_json
      @times_article_url = JSON.parse(times_response)["response"]["docs"][0]["web_url"]
      @times_snippet = JSON.parse(times_response)["response"]["docs"][0]["snippet"]
      @times_headline = JSON.parse(times_response)["response"]["docs"][0]["headline"]["main"]
      @article_img_url = JSON.parse(times_response)["response"]["docs"][0]["multimedia"][0]["url"]
    rescue Exception => e
      puts e.message
    end

    ### TWITTER ####
      @tweets = []
        TWIT_CLIENT.search("#{@obsession}", :result_type => "recent").take(5).each_with_index do |tweet, index|
        @name = tweet.user.screen_name
        @text = tweet.text
        @tweets.push("#{@name} says: '#{@text}'")
      end
    render(:erb, :feeds)
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
