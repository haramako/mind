#!/usr/bin/env ruby
# coding: utf-8

require 'sinatra'
# require 'sinatra/contrib'
require 'sinatra/reloader' if development?
require 'rack/contrib/try_static'
require 'digest/md5'
require 'pp'
require 'fileutils'

configure :development do
  enable :reloader
end

root_dir = File.dirname(__FILE__)
set :haml, format: :html5
set :public_folder, root_dir + '/static'
set :data_dir, root_dir + '/../../Images'
set :tmp_dir, root_dir + '/tmp'
set :tmp_img_dir, settings.tmp_dir + '/split'
set :output_dir, settings.tmp_dir + '/hsv_images'

PNG2HSV = '../bin/png2hsv'

FileUtils.mkdir_p([settings.tmp_dir, settings.tmp_img_dir, settings.output_dir])

use Rack::TryStatic, root: '../../', urls: ['/Images']


CHANNEL_NAMES = {
  HSV: 'HSV',
  D: 'DDR(DoubleDynamicRange)',
  C: '色相（カラーのみ）',
  H: '色相',
  S: '彩度',
  V: '明度',
}

def data_imgs
  Dir.glob(settings.data_dir + '/*.png')
    .reject{|f| f.match /_Light.png$/}
    .map{|f| File.basename(f) }
end

def light_img(filename)
  filename.gsub(/\.png/){'_Light.png'}
end

def img_path(filename)
  settings.data_dir + '/' + filename
end

def img_url(filename)
  if File.exist? settings.data_dir + '/' + filename
    '/Images/' + filename
  else
    '/blank.png'
  end
end

def tmp_img(filename)
  settings.tmp_img_dir + '/' + filename
end

def convert_img(filename, channel)
  if channel == :HSV
    postfix = ''
  else
    postfix = '_' + channel.to_s
  end
  src_img = img_path(filename)
  hash = Digest::MD5.file(src_img).hexdigest
  out_img = tmp_img(hash + '.png')
  unless File.exist? out_img
    system PNG2HSV, '-split', src_img, out_img
  end
  out_img.gsub(/\.png$/){postfix+'.png'}
end

get '/' do
  @imgs = data_imgs
  haml :index
end

get '/img/:id' do
  @id = params[:id]
  haml :img_show
end

get '/img/:id/:channel' do
  img = convert_img(params[:id], params[:channel].to_sym)
  send_file img, :type => :png
end

get '/convert_all' do
  imgs = Dir.glob(settings.data_dir + '/*.png')
         .reject{|f| f.match /_Light.png$/}
         .map{|f| File.basename(f) }

  imgs.each do |f|
    puts 'converting ' + f + ' ...'
    hsv_img = convert_img(f, :HSV)
    FileUtils.cp hsv_img, settings.output_dir + '/' + f
  end
  redirect '/'
end
