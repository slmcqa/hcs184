
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
#require File.dirname(__FILE__) + '/../lib/slmc'

require 'spec_helper'
require 'yaml'

describe "SLMC :: Additional Account Class 2  (Company & House Staff)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @user = "abhernandez"

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "Search Item" do
        package_code = "10000"
        package_description = "PLAN A1 MALE"
        package_code_not_exist = "7777"
        slmc.login(@user, @password).should be_true
        sleep 2
        slmc.click("link=File Maintenance");
        sleep 2
        slmc.click "link=Package", :wait_for => :page
        sleep 5
        slmc.is_element_present('css=input[type="submit"]').should be_true
        slmc.is_text_present("Code").should be_true
        slmc.is_text_present("Description").should be_true
        slmc.is_text_present("Short Name").should be_true
        slmc.is_text_present("Package Type").should be_true
        slmc.is_text_present("Number of Days").should be_true
        slmc.is_text_present("Status").should be_true
        slmc.type("id=txtQuery", package_code);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td").should == package_code
        slmc.is_element_present('css=img[alt="Edit Package"]"').should be_true
        slmc.is_element_present("css=img[alt=\"Package Detail\"]").should be_true
        slmc.is_element_present("css=img[alt=\"Package Rate\"]").should be_true
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        slmc.is_element_present('css=img[alt="Edit Package"]"').should be_true
        slmc.is_element_present("css=img[alt=\"Package Detail\"]").should be_true
        slmc.is_element_present("css=img[alt=\"Package Rate\"]").should be_true
        slmc.type("id=txtQuery", package_code_not_exist);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.is_text_present("Nothing found to display").should be_true


  end
  it "Add Package Header" do
        slmc.login(@user, @password).should be_true
        sleep 3
        slmc.click("link=File Maintenance");
        sleep 3
        slmc.click "link=Package", :wait_for => :page
        sleep 5
        package_description = "PLAN TEST MALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
        package_short_des = "TESTMALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"

        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
         slmc.is_text_present("Nothing found to display").should be_true
        slmc.click("id=btnPkg_add");
        code = "#{(Time.now).strftime("%m%d%Y%H%M%S")}"
         slmc.type "id=txtPkg_code", code             
        slmc.type "id=txtPkg_desc",package_description
        slmc.type "id=txtPkg_shortName",package_short_des
        sleep 6
        slmc.click "id=btnPkg_ok" # :wait_for => :page


        sleep 10
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        package_id = ("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td")
        slmc.click("css=img[alt=\"Edit Package\"]");
        sleep 5
        slmc.select("id=selPkg_status", "label=CANCELLED");
                sleep 5
        slmc.click("id=btnPkg_ok", :wait_for => :page);
        slmc.is_text_present("The record #{package_id} has been saved.")
  end
  it "Add Package Header - Existing Package Header" do
        slmc.click("link=File Maintenance");
        sleep 3
        slmc.click "link=Package", :wait_for => :page
        sleep 5
        package_description = "PLAN TEST MALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
        package_short_des = "TESTMALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
        
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
         slmc.is_text_present("Nothing found to display").should be_true
        slmc.click("id=btnPkg_add");
        code = "#{(Time.now).strftime("%m%d%Y%H%M%S")}"
         slmc.type "id=txtPkg_code", code        
        slmc.type "id=txtPkg_desc",package_description
        slmc.type "id=txtPkg_shortName",package_short_des
        slmc.click "id=btnPkg_ok", :wait_for => :page
        sleep 5
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        slmc.click("id=btnPkg_add");
         slmc.type "id=txtPkg_code", code
        slmc.type "id=txtPkg_desc",package_description
        slmc.type "id=txtPkg_shortName",package_short_des
        slmc.click "id=btnPkg_ok", :wait_for => :page
        sleep 5
        slmc.is_text_present("Description already exist. Try a new one.")
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        package_id = ("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td")
        slmc.click("css=img[alt=\"Edit Package\"]");
        sleep 5
        slmc.select("id=selPkg_status", "label=CANCELLED");
        slmc.click("id=btnPkg_ok", :wait_for => :page);
        slmc.is_text_present("The record #{package_id} has been saved.")
  end
  it "Add Package Header - All Package Type, In ans Out Patient " do
        count_of_row = 22
        x = 0
        while x != count_of_row
              row = x
              slmc.click("link=File Maintenance");
              sleep 3
              slmc.click "link=Package", :wait_for => :page
              sleep 5
              package_description = "PLAN TEST MALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
              package_short_des = "TESTMALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
              
              slmc.type("id=txtQuery", package_description);
              slmc.click "css=input[type=\"submit\"]", :wait_for => :page
              sleep 5
               slmc.is_text_present("Nothing found to display").should be_true
           
              slmc.click("id=btnPkg_add");
             code = "#{(Time.now).strftime("%m%d%Y%H%M%S")}"
              slmc.type "id=txtPkg_code", code                     
              slmc.type "id=txtPkg_desc",package_description
              slmc.type "id=txtPkg_shortName",package_short_des
              package_detail = PatientBillingAccountingHelper::Philhealth.get_read_fm_package_scenario(row)
              package_type = package_detail[:package_type]
              patient_type = package_detail[:patient_type]
              no_of_days = package_detail[:no_of_days]
              if no_of_days == "ONE DAY"
                    no_of_days = 1
              elsif no_of_days == "MORE THAN 1 DAY"
                      no_of_days = 2
              else
                no_of_days = 0
              end
              status = package_detail[:status]
              slmc.select("id=selPkg_packageType", "label=#{package_type}");
              slmc.select("id=selPkg_patientType", "label=#{patient_type}");
              slmc.type("id=txtPkg_numDays", no_of_days);
              slmc.select("id=selPkg_status", "label=#{status}");

              slmc.click "id=btnPkg_ok", :wait_for => :page
              sleep 5
              slmc.type("id=txtQuery", package_description);
              slmc.click "css=input[type=\"submit\"]", :wait_for => :page
              sleep 5
              slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
              package_id = ("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td")
              slmc.click("css=img[alt=\"Edit Package\"]");
              sleep 5
              slmc.select("id=selPkg_status", "label=CANCELLED");
              slmc.click("id=btnPkg_ok", :wait_for => :page);
              slmc.is_text_present("The record #{package_id} has been saved.")
              x+=1
        end
  end
  it "Add and Edit Package Header" do
        slmc.login(@user, @password).should be_true
        slmc.click("link=File Maintenance");
        sleep 3
        slmc.click "link=Package", :wait_for => :page
        sleep 5
        package_description = "PLAN TEST MALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
        package_short_des = "TESTMALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
         slmc.is_text_present("Nothing found to display").should be_true
        slmc.click("id=btnPkg_add");
        code = "#{(Time.now).strftime("%m%d%Y%H%M%S")}"
         slmc.type "id=txtPkg_code", code           
        slmc.type "id=txtPkg_desc",package_description
        slmc.type "id=txtPkg_shortName",package_short_des
        slmc.click "id=btnPkg_ok", :wait_for => :page
        sleep 5
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[6]").should == "ACTIVE"
        package_id = ("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td")
        package_description = package_description + "EDITED"
        package_short_des = package_short_des + "EDITED"
        slmc.click("css=img[alt=\"Edit Package\"]");
        slmc.type("id=txtPkg_desc",package_description);
        slmc.type("id=txtPkg_shortName", package_short_des);
        slmc.type("id=txtPkg_numDays", "2");
        slmc.select("id=selPkg_status", "label=CANCELLED");
        slmc.click "id=btnPkg_ok", :wait_for => :page         
        slmc.is_text_present("The record #{package_id} has been saved.")
        sleep 5
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        package_id = ("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td")
        slmc.click("css=img[alt=\"Edit Package\"]");
        sleep 5
        slmc.select("id=selPkg_status", "label=ACTIVE");
        slmc.click("id=btnPkg_ok", :wait_for => :page);
        slmc.is_text_present("The record #{package_id} has been saved.")
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[6]").should == "ACTIVE"
        slmc.click("css=img[alt=\"Edit Package\"]");
        sleep 5
        slmc.select("id=selPkg_status", "label=CANCELLED");
        slmc.click("id=btnPkg_ok", :wait_for => :page);
        slmc.is_text_present("The record #{package_id} has been saved.")
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[6]").should == "CANCELLED"
  end
  it "Add Package Detail" do
        slmc.login(@user, @password).should be_true
        slmc.click("link=File Maintenance");
        sleep 3
        slmc.click "link=Package", :wait_for => :page
        sleep 5
        package_description = "PLAN TEST MALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
        package_short_des = "TESTMALE #{(Time.now).strftime("%m%d%Y%H%M%S")}"
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
         slmc.is_text_present("Nothing found to display").should be_true
        code = "#{(Time.now).strftime("%m%d%Y%H%M%S")}"
         slmc.type "id=txtPkg_code", code            
        slmc.click("id=btnPkg_add");
        slmc.type "id=txtPkg_desc",package_description
        slmc.type "id=txtPkg_shortName",package_short_des
        slmc.click "id=btnPkg_ok", :wait_for => :page
        sleep 5
        slmc.type("id=txtQuery", package_description);
        slmc.click "css=input[type=\"submit\"]", :wait_for => :page
        sleep 5
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
        slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[6]").should == "ACTIVE"
        slmc.click("css=img[alt=\"Package Detail\"]",:wait_for => :page);
        @mservice_code = ["060000750",	"010000001",	"040854342",	"269409014",	"082400222",	"010002580",	"060000209",	"010001745",	"060003489",	"089403123",	"060000354",	"030000001",	"089000039",	"089500009"]
        @mservice_code.each do |mservice_code|
              slmc.click("id=btnPkgDtl_add");
              slmc.type("id=txtPkgDtl_qty", "1");
              slmc.click("id=btnRefSvcFind");
              slmc.type("id=txtQuery", mservice_code);
              slmc.click("css=input[type=\"button\"]");
              slmc.click("//tbody[@id='package_finder_table_body']/tr/td[2]");
              header_code = slmc.get_text('//*[@id="txtPkgDtl_admPackageCode"]')
              service_code = slmc.get_text('//*[@id="txtRefSrvc_code"]')
              code = header_code + service_code
              slmc.click("id=btnPkgDtl_ok");
              slmc.is_text_present("The record #{code} has been saved.")
        end
    #edit package detail
#
#selenium.click("css=img[alt=\"Edit\"]");
#selenium.click("css=#aPkgDtl_edit-2 > img[alt=\"Edit\"]");
#selenium.click("css=#aPkgDtl_edit-3 > img[alt=\"Edit\"]");
#
#selenium.click("css=img[alt=\"Package Detail Alternative\"]");
#selenium.waitForPageToLoad("30000");
#selenium.click("css=#divPkgDtl-2 > a.admin > img[alt=\"Package Detail Alternative\"]");
#selenium.waitForPageToLoad("30000");
#selenium.click("css=#divPkgDtl-3 > a.admin > img[alt=\"Package Detail Alternative\"]");
#selenium.waitForPageToLoad("30000");
#
#
#    #package alternative
#    selenium.click("id=btnPkgAlt_add");
#    selenium.click("id=btnRefSvcFind");
#    selenium.type("id=txtQuery", "060000749");
#    selenium.click("css=input[type=\"button\"]");
#    selenium.click("//tbody[@id='package_finder_table_body']/tr/td[2]");
#    selenium.type("id=txtPkgAlt_qty", "1");
#    selenium.click("id=btnPkgAlt_ok");
#    slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form/table/tbody/tr/td") #code
#    slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form/table/tbody/tr/td[3]") #Package Detail Code

  end
  it "pacakage rate" do
#    selenium.open("/admin/data/packageList.html");
#selenium.click("css=img[alt=\"Package Rate\"]");
#selenium.waitForPageToLoad("30000");
#selenium.click("id=btnPkgRate_add");
#selenium.select("id=selPkgRate_gender", "label=FEMALE");
#selenium.select("id=selPkgRate_status", "label=CANCELLED");
#selenium.select("id=selPkgRate_status", "label=ACTIVE");
#selenium.type("id=txtPkgRate_packageAmount", "122222");
#selenium.select("id=selPkgRate_pkgChargeCode", "label=SUITE");
#selenium.select("id=selPkgRate_pkgChargeCode", "label=PRIVATE");
#selenium.select("id=selPkgRate_pkgChargeCode", "label=PRESIDENTIAL");
#selenium.select("id=selPkgRate_pkgChargeCode", "label=SUITE");
#
#selenium.type("id=txtPkgRate_effectivityDate", "12312");
#
#
#selenium.click("id=btnPkgRate_ok");
#selenium.waitForPageToLoad("30000");

  end
end

