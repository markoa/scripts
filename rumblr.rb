#!/usr/bin/env ruby

require "net/http"
require "uri"

module Rumblr

  GENERATOR = "rumblr"

  class ResponseError < StandardError
    attr_reader :response
    def initialize(response)
      @response = response
    end
  end

  class AuthError < StandardError; end

  class BadRequestError < StandardError
    attr_reader :message
    def initialize(message)
      @message = message
    end
  end

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
          puts "Created post #{res.body.chomp}"
        when '403'
          raise AuthError.new
        when '400'
          raise BadRequestError.new(res.body)
        else
          raise ResponseError.new(res)
        end
      end
    end

    def regular(title, body)
      post("type" => "regular", "title" => title, "body" => body)
    end

    def quote(text, source=nil)
      post("type" => "quote", "quote" => text, "source" => source)
    end

    def link(name, url, description)
      post("type" => "link", "name" => name, "url" => url, "description" => description)
    end

    def self.tunnel(email, pwd, &block)
      writer = Writer.new(email, pwd)
      writer.instance_eval &block
    end
  end

  class Client
    def self.print_help
      puts "\nRumblr - command line client for posting on your Tumblr blog\n\n"
      puts "Usage: rumblr [regular|quote]\n\n"
    end

    def self.post_regular(email, pwd)
      puts "Title:"
      title = STDIN.gets.strip
      puts "Message:"
      body = STDIN.gets.strip
      Rumblr::Writer.tunnel(email, pwd) do
        regular(title, body)
      end
    end

    def self.post_quote(email, pwd)
      puts "Quote:"
      quote = STDIN.gets.strip
      puts "Source (optional):"
      source = STDIN.gets.strip
      Rumblr::Writer.tunnel(email, pwd) do
        quote(quote, source)
      end
    end

    def self.post_link(email, pwd)
      puts "Name (optional):"
      name = STDIN.gets.strip
      puts "URL:"
      url = STDIN.gets.strip
      puts "Description (optional):"
      desc = STDIN.gets.strip
      Rumblr::Writer.tunnel(email, pwd) do
        link(name, url, desc)
      end
    end

    def self.get_credentials
      email = String.new
      pwd = String.new
      begin
        creds = File.open(File.expand_path("~/.rumblr"))
        email = creds.readline.strip
        pwd = creds.readline.strip
        creds.close
      rescue Exception
        home = File.expand_path("~")
        creds = File.new("#{home}/.rumblr", "w")
        puts "What's your login email on Tumblr?"
        email = gets.strip
        puts "And password?"
        pwd = gets.strip
        creds.puts email
        creds.puts pwd
        creds.close
      end
      [email, pwd]
    end

    def self.run
      email, pwd = get_credentials
      begin
        if ARGV.empty? or ARGV.first == "help"
          print_help
        elsif ARGV.first == "regular"
          post_regular(email, pwd)
        elsif ARGV.first == "quote"
          post_quote(email, pwd)
        elsif ARGV.first == "link"
          post_link(email, pwd)
        end
      rescue ResponseError => re
        puts "Response error: #{re.message}"
      rescue AuthError
        puts "Authentication error: your email address or password "
             "were incorrect."
      rescue BadRequestError => bre
        puts "Error(s) occurred while trying to save your post:\n#{bre.message}"
      end
    end
  end
end

Rumblr::Client.run
