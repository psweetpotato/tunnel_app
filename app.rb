require 'sinatra/base'
require 'securerandom'
require 'httparty'
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

  get('/feeds') do
    @obsession = params[:obsession].capitalize
    #### TIMES ######
    @base_url = "http://api.nytimes.com/svc/search/v2/articlesearch.json?"
    @times_url = "#{@base_url}fq=#{@obsession}&api-key=#{YORK_SEARCH_KEY}"
    times_response = HTTParty.get("#{@times_url}").to_json
    @times_article_url = JSON.parse(times_response)["response"]["docs"][0]["web_url"]
    @times_snippet = JSON.parse(times_response)["response"]["docs"][0]["snippet"]
    @times_headline = JSON.parse(times_response)["response"]["docs"][0]["headline"]["main"]
# binding.pry
    @article_img_url = JSON.parse(times_response)["response"]["docs"][0]["multimedia"][0]["url"]

    ### TWITTER ####
      @tweets = []
        TWIT_CLIENT.search("#{@obsession}", :result_type => "recent").take(5).each_with_index do |tweet, index|
        @name = tweet.user.screen_name
        @text = tweet.text
        @tweets.push("#{@name} says: '#{@text}'")
      end
    render(:erb, :feeds)
  end

  get('/@article_img_url') do
    @article_img_url
    render(:erb, :images)
  end

end
