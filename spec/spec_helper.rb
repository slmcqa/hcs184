require 'selenium/rspec/spec_helper'

class Selenium::RSpec::Reporting::SystemCapture

  alias_method :capture_system_state_with_out_error_encountered, :capture_system_state
  

  def capture_system_state_with_error_encountered
    capture_system_state_with_out_error_encountered
    if (@selenium_driver.is_text_present("An Error was encountered. Please contact your system administrator.") || @selenium_driver.is_text_present("Yikes"))
      @selenium_driver.go_back
      @selenium_driver.wait_for_page_to_load "300000"
    end
  end

  def get_location_instead_of_capture_system_screenshot
    #new_capture_system_screenshot
    url = @selenium_driver.get_location
    File.open(@file_path_strategy.file_path_for_page_url(@example), "w") { |f| f.write url }
  end
  
  alias_method :capture_system_state, :capture_system_state_with_error_encountered
  alias_method :capture_system_screenshot, :get_location_instead_of_capture_system_screenshot

end
class Selenium::RSpec::Reporting::FilePathStrategy


  def relative_file_path_for_page_url(example)
    "#{relative_dir}/example_#{example.reporting_uid}_page_url.txt"
  end

  def file_path_for_page_url(example)
    file_path relative_file_path_for_page_url(example)
  end

  alias_method :relative_file_path_for_system_screenshot, :relative_file_path_for_page_url
  alias_method :file_path_for_system_screenshot, :file_path_for_page_url

end
class Selenium::RSpec::Reporting::HtmlReport

  def div_section(url)
    <<-EOS
          <br/>
          <div>[ Page URL:
            <a href="#{url}">#{url}</a> ]</div>
          <br/><br/>
    EOS
  end

  def new_replace_placeholder_with_system_state_content(result, example)
    result.gsub! PLACEHOLDER, logs_and_screenshot_with_url_sections(example)
  end


  def logs_and_screenshot_with_url_sections(example)
    dom_id = "example_" + example.reporting_uid
    page_url_url = @file_path_strategy.relative_file_path_for_page_url(example)
    page_screenshot_url = @file_path_strategy.relative_file_path_for_page_screenshot(example)
    snapshot_url = @file_path_strategy.relative_file_path_for_html_capture(example)
    remote_control_logs_url = @file_path_strategy.relative_file_path_for_remote_control_logs(example)

    html = ""
    if File.exists? @file_path_strategy.file_path_for_system_screenshot(example)
      html << toggable_section(dom_id, :id => "page_url", :name => "Page Url", :url => page_url_url)
      f = File.open(@file_path_strategy.file_path_for_page_url(example))
      url = f.readline
      html << div_section(url)
    end
    if File.exists? @file_path_strategy.file_path_for_html_capture(example)
      html << toggable_section(dom_id, :id => "snapshot", :url=> snapshot_url, :name => "Dynamic HTML Snapshot")
    end
    if File.exists? @file_path_strategy.file_path_for_remote_control_logs(example)
      html << toggable_section(dom_id, :id => "rc_logs", :url=> remote_control_logs_url, :name => "Remote Control Logs")
    end
    if File.exists? @file_path_strategy.file_path_for_page_screenshot(example)
      html << toggable_image_section(dom_id, :id => "page_screenshot", :name => "Page Screenshot", :url => page_screenshot_url)
    end

    return html
  end

  alias_method :logs_and_screenshot_sections, :logs_and_screenshot_with_url_sections
  alias_method :replace_placeholder_with_system_state_content, :new_replace_placeholder_with_system_state_content
  
end