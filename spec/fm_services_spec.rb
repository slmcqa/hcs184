

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
#require File.dirname(__FILE__) + '/../lib/slmc'

require 'spec_helper'
require 'yaml'

#USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'
describe "SLMC :: File Maintenance Services" do

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

  it "Login CSS user" do
    slmc.login(@user, @password).should be_true
  end
  it  "Go to Services landing Page" do
      slmc.go_service
    #  slmc.fm_services_landing_page_checking.should be_true
  end
  it "validate if new service button is functioning" do
      slmc.go_to_services_page
     # slmc.fm_services_landing_page_checking.should be_true
      slmc.fm_services_click_new_btn
      slmc.is_element_present("id=divSvcfPopup").should be_true
      slmc.is_element_present("id=chkSvcfCsgn").should be_true
      slmc.get_selected_label("id=selSvcfStatus").should == "ACTIVE"
  end
  it "CSS Adding data (Basic View)" do
       num = AdmissionHelper.range_rand(10,99).to_s
      @@csscode = "1m2m3#{num}"
      slmc.go_to_services_page
    #  slmc.fm_services_landing_page_checking.should be_true
      slmc.fm_services_click_new_btn
      slmc.is_element_present("id=divSvcfPopup").should be_true
      slmc.is_element_present("id=chkSvcfCsgn").should be_true
      slmc.get_selected_label("id=selSvcfStatus").should == "ACTIVE"
      slmc.fm_services_select_dept(:dept=>"CSS")
      slmc.fm_services_input_code(:dept=>"CSS",:code => @@csscode)
      slmc.is_element_present("id=imgSvcfCodeOk").should be_true

      @@desc = "TEST CSS DESC"
      @@cllabel = "TEST CLINICAL LABEL"
      @@cltag = "TEST"
      @@phcode = "PHS05"
      @@ordertype = "ORT02"
      @@owningdept = "0008"
      slmc.fm_services_input_details(:dept=>"CSS",
                                     :desc=>@@desc,
                                     :cllabel=>@@cllabel,
                                     :cltag=>@@cltag,
                                     :phcode => @@phcode,
                                     :ordertype => @@ordertype,
                                     :owningdept => @@owningdept
                                    )
      slmc.is_element_present("//thead[@id='tbhSvcfDepts']/tr/th").should be_true
      slmc.is_element_present("//a[@id='aAppAll-uom']/img").should be_true
      slmc.is_element_present("//a[@id='aAppAll-phBft']/img").should be_true
      slmc.is_element_present("//a[@id='aAppAll-mrp']/img").should be_true
      slmc.is_element_present("//a[@id='aAppAll-inventory']/img").should be_true
#      slmc.is_element_present("//a[@id='aAppAll-opd']/img").should be_true
      slmc.fm_services_input_grid_details(:dept=>"CSS",
                                          :uofm => "BOX",
                                          :phbenefit=> "PHB05",
                                          :price => 100
                                        )
      slmc.fm_services_click_ok_btn(:dept=>"CSS")
      slmc.fm_services_click_ok_btn_checking(:dept=>"CSS",:code => @@csscode).should be_true
   end
  it "Add Multiple Service" do
        slmc.login(@user, @password).should be_true
        slmc.go_service
        count = 4
        while count != 300

        slmc.click("id=optServiceItemsRef")
        sleep 5
        fm = PatientBillingAccountingHelper::Philhealth.fm_add_service_scenario(count)
#        num =  AdmissionHelper.range_rand(10,99).to_s
#        mservice =  "wwwww#{num}"
         slmc.fm_services_click_new_btn
#         sleep 6
#         slmc.click("id=aSvcfDeptsAdd");
#        sleep 3
#        slmc.add_selection("id=lstNumsOrgUnitsRight", "label=CENTRAL STERILE SUPPLY");
#        sleep 3
#        slmc.click("id=btnNumsLeft");
#        sleep 3
#        slmc.click("id=btnNumsOk");
        sleep 3
        slmc.click("id=aSvcfDeptsAdd");
        sleep 3
        slmc.add_selection("id=lstNumsOrgUnitsLeft", "label=#{fm[:using]}");
        sleep 3
        slmc.click("id=btnNumsRight");
        sleep 3
        slmc.click("id=btnNumsOk");
        sleep 10
         mser =  slmc.select_scenario(:deptcode =>fm[:depcode], :ort_type => fm[:order_type],:mcode =>fm[:mservice] )
    #    mser =  slmc.select_scenario(:deptcode =>fm[:depcode], :ort_type => fm[:order_type],:mcode =>mservice)
         sleep 3
         slmc.click("css=#aSvcfDept > img");

         sleep 3
        slmc.type("id=txtNuQuery", fm[:owning]);
         sleep 3
        slmc.click("id=btnNuFindSearch");
         sleep 3
        slmc.click("id=tdNuCode-0");
         sleep 3
        slmc.click("css=#aSvcfPhCode > img");
        puts ":ph_code = #{fm[:ph_code]}"
         sleep 3
        slmc.type("id=txtNliQuery", fm[:ph_code])
         sleep 3
        slmc.click("id=btnNliFindSearch");
         sleep 3
        slmc.click("id=tdNliCode-0");
        sleep 3
        newcode = fm[:owning]
        #slmc.click("id=aSvcfDeptUom-0008");
        slmc.click("css=#aSvcfDeptUom-#{newcode} > img")
        sleep 3
        slmc.type("id=txtNliQuery", fm[:uom]);
        sleep 3
        slmc.click("id=btnNliFindSearch");
        sleep 3
        slmc.click("id=tdNliCode-0");
        sleep 3
        slmc.click("css=#aSvcfDeptPhBft-#{newcode}");
        sleep 3
        slmc.type("id=txtPliQuery",  fm[:ph_benefits]);
        sleep 3
        slmc.click("id=btnPliFindSearch");
        sleep 3
        slmc.click("id=tdPliCode-0");
        sleep 3
        slmc.click("id=aSvcfDeptPriceOpd-#{newcode}");
        sleep 3
        slmc.type("id=txtSvcfDeptPriceOpd-#{newcode}", fm[:rate]);
        sleep 3
        slmc.click("id=txtSvcfDesc")
        sleep 2
        mser =  slmc.select_scenario(:deptcode =>fm[:depcode], :ort_type => fm[:order_type],:mcode =>fm[:mservice] )
        sleep 3
        slmc.click("id=txtSvcfDesc")
        sleep 2
        slmc.click('//*[@id="btnSvcfOk"]',:wait_for =>:page)
       sleep 10
       slmc.click("id=optServiceItemsTmp")
       sleep 3
       slmc.type("id=txtQuery",mser)
       sleep 2
       slmc.click('css=input[type="submit"]') #,:wait_for =>:page)
       sleep 10
       result = slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/div[8]/div/table/tbody/tr/td")
       if (result).should == mser
         puts"GOOD"
              ngayon = (Time.now).strftime("%m%d%Y%H%M%S")
              stat = "PASSED"
             Database.connect
              q = "INSERT INTO MY_TEST_TABLE VALUES('#{mser}','#{ngayon}','#{stat}')"
              Database.update_statement q
              Database.logoff
       else
         puts"BAD"
       end
        puts "mservice_code = #{mser}"
        puts "count - #{count}"
        count += 1
     #           slmc.go_service
        end
   end
end

