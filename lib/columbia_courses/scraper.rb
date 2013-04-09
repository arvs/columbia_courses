require 'open-uri'
require 'nokogiri'
require 'pry'

class ColumbiaCourses::Scraper
  def initialize(params)
    @base_url = params[:base_url]
    @semesters = params[:semesters]
    @depts = params[:depts]
    @subjects = params[:subjects]
    @kw = params[:kw]
  end

  def params_to_query(params)
    params.map {|p, v| "#{p}=#{URI.escape(v.to_s)}"}.join('&')
  end

  def append_url(url, params = {})
    uri = url
    uri.query = uri.query.nil? ? params_to_query(params) : [uri.query, params_to_query(params)].join('&') unless params.empty?
    uri.to_s
  end

  def crawl_search_page(query)
    params = {
      :q => query, 
      :site => "Directory_of_Classes", 
      :num => 100, 
      :filter => 0,
      :entqr => 0, 
      :ud => 1,
      :sort => "date%3AD%3AL%3Ad1", 
      :output => "xml_no_dtd",
      :oe => "UTF-8",
      :ie => "UTF-8",
      :client => "DoC",
      :proxystylesheet => "DoC",
      :proxyreload => 1
    }
    first_page = append_url("http://search.columbia.edu/search/", params)
    puts first_page
    first_page = Nokogiri::HTML(open(append_url("http://search.columbia.edu/search/", params)))
    binding.pry
    return nil
  end

  def crawl()
    if @kw
      return crawl_search_page(@kw.join(" "))
    else
      if @subjects.count
        pages = @subjects.map { |x| "#{@base_url}sel/subj-#{x[0].capitalize}.html" }
      elsif @depts
        pages = @depts.map { |x| "#{@base_url}sel/dept-#{x[0].capitalize}.html" }
      else
        pages = ('A'..'Z').to_a.map {|x| "#{@base_url}sel/dept-#{x}.html" }
      end
    end
  end
end