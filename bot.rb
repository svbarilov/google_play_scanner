require 'typhoeus'
require 'csv'

module Market
  class Bot


def self.zaherachit(category, identifier, pages)
  $results = []
  app_urls = get_all_app_urls(category, identifier, pages)
  call(app_urls)
  save_results($results)
end



private


def self.get_all_app_urls(category, identifier, pages)
  @category = category
  @identifier = identifier
  @pages = pages
  @app_urls = []
  [*1..@pages].each do |page|
    url = "https://play.google.com/store/apps/category/#{@category.to_s.upcase}/collection/#{@identifier.to_s}?start=#{page}&num=48&hl=en"
    apps = Typhoeus.get(url).body
    app_urls = apps.scan(/href="(\/store\/apps\/details.+?)"/).map{|uri|
      uri = uri.to_s.chop.chop.reverse.chop.chop.reverse
      "https://play.google.com#{uri}"
    }
    @app_urls << app_urls.uniq
    @app_urls = @app_urls.flatten
  end
  @app_urls = @app_urls.flatten.uniq
  @app_urls
end



def self.call(urls)
  urls.each do |url|
    process_page(url)
  end
  @hydra.run
end


def self.save_results(results)
  CSV.open("results/#{Time.now.to_s.chop.chop.chop.chop.chop.chop}-#{@category}-#{@identifier}.csv", "w") do |csv|
    results.each do |line|
    csv << line
    end
  end
end


def self.process_page(url)
  @hydra = Typhoeus::Hydra.hydra
  request = Typhoeus::Request.new(url)
  request.on_complete do |response|
    response = response
    result = parse(response.body)
  end
  @hydra.queue(request)
end



def self.parse(body)
  results = {}
  body = body.to_s
  results[:title]     = body.scan(/document-title.+?>.+?<div>([^<]+)/).flatten.to_s.reverse.chop.chop.reverse.chop.chop
  results[:developer] = body.scan(/document-subtitle primary.+?store\/apps\/developer\?id=([^<]+)/).flatten.to_s.to_s.gsub("+", " ").chop.chop.chop.reverse.chop.chop.reverse.chop.chop.chop 
  results[:email]      = body.scan(/class="dev-link" href="mailto:(.+?)"/).flatten.uniq.to_s.reverse.chop.chop.reverse.chop.chop

  # comment this line here to NOT output results in terminal
  puts %Q{"#{results[:email]}", "#{results[:title]}", "#{results[:developer]}"}
  puts ""
  
  $results << [results[:email], results[:title], results[:developer]]
  puts $results.count
end  




##### end class and module
 end 
end