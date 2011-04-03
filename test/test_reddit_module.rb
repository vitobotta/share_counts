require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class RedditModuleTest < ActiveSupport::TestCase
  test ".info_for should return a hash with score and permalink for the given url" do
    stub_request(:get, Reddit.api).with(:query => to_merged_hash(Reddit.params)).to_return(:body => Reddit.url_info_json)
    assert_equal({ "permalink" => "/r/ruby/comments/ffik5/geeky_cv_d/", "score" => 30}, ShareCounts::Reddit.info_for(SOME_URL))
  end

  test ".info_for with raise_exceptions=true should raise exception" do
    stub_request(:get, Reddit.api).with(:query => to_merged_hash(Reddit.params)).to_raise(Exception)
    assert_raise(Exception) { ShareCounts::Reddit.info_for(SOME_URL, true) }
  end
  
  test ".by_domain should return permalink and score for each URL Reddit knows for the given domain" do
    stub_request(:get, "http://www.reddit.com/domain/vitobotta.com.json").to_return(:body => Reddit.by_domain_json)
    
    result = {
      "http://vitobotta.com/protect-wordpress-blogs-administration-prying-eyes/"  =>  {
        "permalink" => "/r/Wordpress/comments/g51dn/protect_your_wordpress_blogs_administration_from/",
        "score"     => 8
      },
      
      "http://vitobotta.com/why-isnt-ssl-on-by-default-for-all-websites/" => {
        "permalink" => "/r/geek/comments/fuepg/why_isnt_ssl_turned_on_by_default_for_all_websites/",
        "score"     => 4
      },
      
      "http://vitobotta.com/faster-internet-browsing-alternative-dns-servers-fast-local-cache-bind/" => {
        "permalink" => "/r/apple/comments/fmkxz/faster_internet_browsing_with_alternative_dns/",
        "score"     => 22
      },

      "http://vitobotta.com/web-typography-techniques-usability-performance-seo-security/" => {
        "permalink" => "/r/web_design/comments/fhw72/a_uptodate_look_at_the_state_of_web_typography/",
        "score"     => 3
      },

      "http://vitobotta.com/cv-resume/" => {
        "permalink" => "/r/ruby/comments/ffik5/geeky_cv_d/",
        "score"     => 29
      },

      "http://vitobotta.com/share-counts-gem-social-networks/" => {
        "permalink" => "/r/ruby/comments/fceyq/share_counts_ruby_gem_the_easiest_way_to_check/",
        "score"     => 4
      },

      "http://vitobotta.com/serialisable-validatable-tableless-model/" => {
        "permalink" => "/r/ruby/comments/fb585/a_serialisable_and_validatable_tableless_model_to/",
        "score"     => 2
      },

      "http://vitobotta.com/smarter-faster-backups-restores-mysql-databases-with-mysqldump/" => {
        "permalink" => "/r/Database/comments/faaji/smarter_faster_backups_and_restores_of_mysql/",
        "score"     => 5
      },

      "http://vitobotta.com/awesomeprint-similar-production/" => {
        "permalink" => "/r/ruby/comments/fa2k4/why_you_should_think_twice_before_using_awesome/",
        "score"     => 7
      },

      "http://vitobotta.com/migrating-from-wordpress-to-jekyll-part-one-why-I-gave-up-on-wordpress/" => {
        "permalink" => "/r/webdev/comments/g8yy9/migrating_from_wordpress_to_jekyll_part_1_why_i/",
        "score"     => 0
      },

      "http://vitobotta.com/painless-hot-backups-mysql-live-databases-percona-xtrabackup/" => {
        "permalink" => "/r/Database/comments/fc3q5/painless_ultra_fast_hot_backups_and_restores_of/",
        "score"     => 0
      }

    }
    
    assert_equal(result, ShareCounts::Reddit.by_domain("vitobotta.com"))
  end
  
  
  test ".by_domain with raise_exceptions=true should raise exception" do
    stub_request(:get, "http://www.reddit.com/domain/vitobotta.com.json").to_raise(Exception)
    assert_raise(Exception) { ShareCounts::Reddit.by_domain("vitobotta.com", true) }
  end
end