require 'sinatra'
require 'sinatra/base'
require 'sinatra/reloader' if development?
require 'rubygems'
require 'logger'

# Basic home/visitor route without auth
class App < Sinatra::Base

  get '/' do
    redirect to("/p/li_home")
  end

  # ERROR PAGES
  error 401 do
    redirect to('/pages/401.html')
  end

  error 404 do
    redirect to('/pages/404.html')
  end


end
