class ColumbiaCourses
  @@base_url = "http://www.columbia.edu/cu/bulletin/uwb/"
  def self.all(params)
    params[:base_url] ||= @@base_url
    scraper = Scraper.new(params)
    return Catalog.new(scraper.crawl())
  end
end
require File.join(File.expand_path(File.dirname(__FILE__)), 'columbia_courses/scraper')
require File.join(File.expand_path(File.dirname(__FILE__)), 'columbia_courses/catalog')
