require 'rubygems'
require 'benchmark'
require 'sinatra'
require 'json'
#require 'pry' if development?
#require "sinatra/reloader" if development?
#require 'awesome_print'
require './settings.rb'
require './parser.rb'
require './grid.rb'
require './food.rb'
require './painter.rb'
require './tree.rb'
require './squirrel.rb'
require './snake.rb'
require './food.rb'
Dir["lib/*.rb"].each {|file| require_relative file }
Dir["config/*.rb"].each {|file| require_relative file }

set :port, ENV['PORT']
set :bind, '0.0.0.0'
set :public_folder, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__) + '/public'

MODE = Settings.get("my_snake","st_method") # default Breadth first
DEV = development?

# Start game
#
# Example input
# {
#   "width": 20,
#   "height": 20,
#   "game_id": "b1dadee8-a112-4e0e-afa2-2845cd1f21aa"
# }
#
get '/' do
  	res = {
    	color:"#991f00",
      head: 'evil',
      tail: 'round-bum',
      apiversion: '1',
      version: '1 Alpha'
  	}
    return res.to_json
end

post '/start' do
  	res = {
    	color: "#" + Settings.get("my_snake", "color"),
    	head_url: Settings.get("my_snake","head_url"),
      name: Settings.get("my_snake","name"),
    	taunt: "ゴロゴロ",
      head_type: Settings.get("my_snake", "head_type"),
      tail_type: Settings.get("my_snake", "tail_type")
  	}
    return res.to_json
end

# Calculates the next move of my snake!
#
# @param Request
#
# @return [Hash] contains a move and taunt
#
# @example Response
#
# {
#   move: "up",
#   taunt: "gorogorogoro"
# }
#

post '/move' do
  requestBody = request.body.read
  parser = Parser.new(body: requestBody) 
  #1. Make a grid!
  g = Grid.new(
    width: parser.width, 
    height: parser.height,
    me: parser.you,
    snakes: parser.snakes.collect{|s| Snake.new(id: s["id"], coords: parser.snake(s), health: s["health"])},
    food: parser.food.collect{|f| Food.new(x: f["x"], y: f["y"])})
  # g.print

  #2. Paint that grid!
  p = Painter.new(g)
  p.paint
  p.grid.print if DEV

  #3. Make a tree with the painted grid!
  t = Tree.new(p.grid)
  t.build_tree

  #4. Use a squirrell to traverse the grid
  sq = Squirrel.new(tree: t)

  case MODE
  when "D"
    dir = sq.bottoms_up_method
  when "B"
    dir = sq.bfd_method
  else
    dir = sq.bfd_method
  end
	return {
  	move: dir,
  	taunt: ""
	}.to_json
end

post '/end' do
  return { message: 'Game over'}.to_json
end

