#!/usr/bin/env ruby

require "net/http"
require "uri"

module Rumblr

  GENERATOR = "rumblr"

  class Writer
    attr_accessor :email, :password
      
    def initialize(email, password)
      @email = email
      @password = password
    end

    def post(data)
      Net::HTTP.start("www.tumblr.com") do |http|
        req = Net::HTTP::Post.new "/api/write"
        req.set_form_data({
          "email" => @email,
          "password" => @password,
          "generator" => GENERATOR
        }.merge(data))
        
        res = http.request req

        case res.code
        when '201'
          return res.body.chomp
        when '403'
          puts "Authentication error (#{@email}, #{@password})"
          #raise AuthError.new
        when '400'
          puts "Bad request: #{res.body}"
          #raise BadRequestError.new(res.body)
        else
          puts "Response error #{res}"
          #raise ResponseError.new(res)
        end
      end
    end

    def regular(title, body)
      post("type" => "regular", "title" => title, "body" => body)
    end

    def self.tunnel(email, pwd, &block)
      writer = Writer.new(email, pwd)
      writer.instance_eval &block
    end
  end
end

### test

def test_regular(email, pwd)
  Rumblr::Writer.tunnel(email, pwd) do
    regular("Gotta see this", "the body baby")
  end
end

###

begin
  creds = File.open(File.expand_path("~/.rumblr"))
  email = creds.readline.strip
  pwd = creds.readline.strip
  creds.close
rescue Exception
  puts "trying.."
  home = File.expand_path("~")
  creds = File.new("#{home}/.rumblr", "w")
  puts "What's your login email on Tumblr?"
  email = gets.strip
  puts "And password?"
  pwd = gets.strip
  creds << email
  creds << pwd
  creds.close
end

test_regular(email, pwd)
