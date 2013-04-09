require 'open-uri'
require 'nokogiri'
require 'pry'
require 'json'

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
    uri = URI.parse(url)
    uri.query = uri.query.nil? ? params_to_query(params) : [uri.query, params_to_query(params)].join('&') unless params.empty?
    uri.to_s
  end

  def courses_from_search(page)
    if @semesters
      in_semester = lambda {|c| @semesters.any? {|s| c.include? s}}
      return page.css(".l").map {|x| x.attr('href') if in_semester[x]}.compact.to_set
    else
      return page.css(".l").map {|x| x.attr('href')}.compact.to_set
    end
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
    first_page = Nokogiri::HTML(open(append_url("http://search.columbia.edu/search", params)))
    num_results = first_page.css("#top_results_range_of_total").text().match(/100 of (\d+).*/)[1].to_i
    course_pages = courses_from_search(first_page)
    (100..num_results).step(100).each { |start| 
      params[:start] = start
      page = Nokogiri::HTML(open(append_url("http://search.columbia.edu/search", params)))
      course_pages += courses_from_search(page)
    }
    return course_pages
  end

  def crawl_dept_subj(subj = true, all_depts=false)
    if @semesters
      joined_sems = @semesters.map {|x| x.gsub(/\s/, '')}
      in_semester = lambda {|c| joined_sems.any? {|s| c.include? s}}
    else
      in_semester = lambda { |c| true }
    end
    if subj
      q = 'subj'
      filter = @subjects
    else
      q = 'dept'
      filter = @depts
    end
    if all_depts
      filter = ('A'..'Z').to_a.map {|x| "#{@base_url}sel/dept-#{x}.html" }
    end
    pages = filter.map {|x| "#{@base_url}sel/#{q}-#{x[0].capitalize}.html"}
    sub_pages = Set.new
    pages.each {|p|
      h = Nokogiri::HTML(open(p)) 
      sub_pages += h.css('tr').map {|row| row.css('td a').map{ |sem| "http://columbia.edu" + sem.attr('href') if in_semester[sem.text()]}.compact if filter.include? row.children[0].text()}.flatten.compact
    }
    course_pages = Set.new
    sub_pages.each {|p|
      page = Nokogiri::HTML(open(p))
      links = page.css('tr td a').map { |x| "http://columbia.edu" + x.attr('href') if x.attr('href').include? "subj" and not x.attr('href').include? '_text.html'}.compact.to_set
      course_pages += links
    }
    return course_pages
  end

  def crawl(outfile="temp.json")
    if @kw
      course_pages = crawl_search_page(@kw.join(" "))
    else
      if @subjects
        course_pages = crawl_dept_subj(true)
      elsif @depts
        course_pages = crawl_dept_subj(false)
      else
        course_pages = crawl_all(false, true)
      end
    end
    File.open(outfile, 'w') { |file|
      file.write(JSON.dump(course_pages.to_a))
    }
  end
end