require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "CTMS" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

  end

  after(:all) do
 #   slmc.logout
    slmc.close_current_browser_session
  end
  it "CTMS" do
      slmc.open("/slmc_ctms/index.htm");
      slmc.type("name=j_username", "user2");
      slmc.type("name=j_password", "a");
      slmc.click "css=button.btnSend",:wait_for => :page
      slmc.is_text_present("CLINICAL TEAM MESSAGING SYSTEM - MEDICAL RECORDS AND MANAGEMENT SERVICES")
      nosent = 1
      x = ""
      while nosent != 0
            msg = "my#{x}"
            slmc.click("css=button.btnWrite",:wait_for => :page);
            #slmc.type("id=todoctor", "LIAO");
             slmc.type("id=todoctor", "LIAO");
             slmc.type_keys("id=todoctor",32)
         #    slmc.getEval("window.jQuery('div[id=as-values-todoctor]')");
     #       slmc.wait_for_element('//*[@id="as-selections-todoctor"]'," ")
            sleep 3
            slmc.wait_for_element("css=#as-result-item-2408 > li");
            slmc.click("css=#as-result-item-2408 > li");
           # slmc.click('//*[@id="as-result-item-2408"]')
            slmc.click("css=#as-result-item-2408 > li");
            slmc.select("id=templateName", "label=Sample template");

            msg = slmc.get_text('//*[@id="messageContent"]')
     #       slmc.click("xpath=(//button[@type='button'])[3]");
            slmc.click("css=input.btnSend");
sleep 10
           username = "sandy"
            sendfrom = "+639328907234"
            sentto ="639493818353"
            datetimesent = Time.now.strftime("%d/%m/%Y %H:%M:%S")
            Database.connect
            t = "INSERT INTO SLMC.MY_SENDER VALUES('#{username}','#{sendfrom}', '#{msg}', '#{sentto}', '#{datetimesent}')"
            Database.update_statement t
            Database.logoff
         #   slmc.click('//*[@id="send"]');
         slmc.wait_for_elements("id=send");
            slmc.click("id=send");

            sleep 10
             slmc.click("//html/body/div[15]/div[3]")
            sleep 10

            nosent -=1
      end
  end
end

