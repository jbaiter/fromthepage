require 'csv'

class Collection < ActiveRecord::Base
  include CollectionStatistic

  has_many :works, -> { order 'title' } #, :order => :position
  has_many :notes, -> { order 'created_at DESC' }
  has_many :articles
  has_many :document_sets, -> { order 'title' }
  has_many :categories, -> { order 'title' }
  has_many :deeds, -> { order 'created_at DESC' }
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  has_and_belongs_to_many :owners, :class_name => 'User', :join_table => :collection_owners
  attr_accessible :title, :intro_block, :footer_block, :picture
#  attr_accessor :picture

  validates :title, presence: true, length: { minimum: 3 }
  
  mount_uploader :picture, PictureUploader

  scope :order_by_recent_activity, -> { includes(:deeds).order('deeds.created_at DESC') }

  def export_subjects_as_csv
    csv_string = CSV.generate(:force_quotes => true) do |csv|
      csv << %w{ Work_Title Page_Title Page_Position Page_URL Subject Text Category Category Category }
      self.works.each do |work|
        work.pages.each do |page|
          page_url="http://localhost:3000/display/display_page?page_id=#{page.id}"
          page.page_article_links.each do |link|
            display_text = link.display_text.gsub("<lb/>", ' ').gsub("\n", "")
            article = link.article
            category_array = []
            article.categories.each do |category|
              category_array << category.title
            end
            csv << [work.title, page.title, page.position, page_url, link.article.title, display_text, category_array.sort].flatten
          end
        end
      end
    end
    csv_string
  end

  def show_to?(user)
    (!self.restricted && self.works.present?) || (user && user.like_owner?(self))
  end


end