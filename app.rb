require 'sinatra/base'

class App < Sinatra::Base

  ########################
  # Configuration
  ########################

  configure do
    enable :logging
    enable :method_override
    enable :sessions
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

  TWIT_API_KEY = "XsBbNJU6XDq3Bweq55fdwAczX"
  TWIT_SECRET = "qYZxGoTtmcxCfdSEZ6bnX9cjFTaEBESGyPkZhXk3pngZ3GMnEM"
  TWIT_OWNER_ID = "2699174835"
  TWIT_ACCESS_TOKEN = "2699174835-4H3CChw71Aj99c442vSXjLxwgRmEQEkHNTQxMv9"
  TWIT_ACCESS_TOKEN_SECRET = "EAhTmi6Cl7uxM2oTCYV1y5C80TeT1jB7vdn2J9NAFfg2q"


  ########################
  # Routes
  ########################

  get('/') do
    render(:erb, :index)
  end
end
