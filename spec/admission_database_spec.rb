require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

#USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Admission page::Database Checking" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @user = "sel_adm4"
    @patient1 = Admission.generate_data

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "ADD PATIENT - ALL FIELDS" do
        slmc.login(@user, @password).should be_true
        slmc.admission_search(:pin => "1")
        @@pin = slmc.create_new_patient(@patient1)
        puts @@pin
        Database.connect
        a =  "SELECT * FROM SLMC.TXN_PATMAS WHERE PIN ='#{@@pin}'"
        b =  "SELECT * FROM SLMC.TXN_PATMAS_ADDL WHERE PIN ='#{@@pin}'"
        c = "SELECT * FROM SLMC.TXN_PATMAS_ADDR WHERE PIN ='#{@@pin}'"
        d = "SELECT * FROM SLMC.TXN_PATMAS_CONTACT WHERE PIN ='#{@@pin}'"
        e = "SELECT * FROM SLMC.TXN_PATMAS_ID WHERE PIN ='#{@@pin}'"
        f = "SELECT * FROM SLMC.TXN_PATMAS_RELATIONS WHERE PIN ='#{@@pin}'"
        g = "SELECT * FROM SLMC.TXN_PATMAS_SPOUSE WHERE PIN ='#{@@pin}'"
        #q = "select RB_TRANS_NO from TXN_PBA_ROOM_BED_TRANS where RB_TRANS_NO = (select MAX(RB_TRANS_NO) from TXN_PBA_ROOM_BED_TRANS)"
        aa = Database.select_statement a
        bb = Database.select_statement b
        cc = Database.select_statement c
        dd = Database.select_statement d
        ee = Database.select_statement e
        ff = Database.select_statement f
        gg = Database.select_statement g
        aa.should_not == nil
        bb.should_not == nil
        cc.should_not == nil
        dd.should_not == nil
        ee.should_not == nil
        ff.should_not == nil
        gg.should_not == nil
        Database.logoff
  end
  it "ADMIT PATIENT - FILL OUT ALL FIELDS" do
        slmc.login(@user, @password).should be_true
        slmc.admission_search(:pin => @@pin)
        slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
        :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."
        visit_no = slmc.get_visit_number_using_pin(@@pin)
        Database.connect
        a = "SELECT RB_STATUS FROM SLMC.REF_ROOM_BED WHERE BEDNO IN (SELECT TXN_ADM_IN.BEDNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = '#{visit_no}')"
        b = "SELECT * FROM SLMC.TXN_ADM_DIAGNOSIS WHERE VISIT_NO = '#{visit_no}'"
        c = "SELECT * FROM SLMC.TXN_ADM_DOCTORS WHERE VISIT_NO = '#{visit_no}'"
        d = "SELECT * FROM SLMC.TXN_ADM_ENCOUNTER WHERE PATIENT_TYPE = 'I' AND VISIT_NO = '#{visit_no}'"
        e = "SELECT * FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = '#{visit_no}'"
        f = "SELECT COUNT(*) FROM SLMC.TXN_PBA_GUARANTOR_INFO  WHERE VISIT_NO = '#{visit_no}'"
        aa = Database.select_statement a
        bb = Database.select_statement b
        cc = Database.select_statement c
        dd = Database.select_statement d
        ee = Database.select_statement e
        ff = Database.select_all_rows f
        #
        #      xx = ff.count
        #      while xx != -1
        #          ff = ff[xx]
        #          puts ff
        #          xx-=1
        #      end
        aa.should_not == nil
        bb.should_not == nil
        cc.should_not == nil
        dd.should_not == nil
        ee.should_not == nil
        ff.should_not == nil
        Database.logoff
  end
  it "EDIT PATIENT - ALL FIELDS" do
@patient1 = Admission.generate_data
slmc.login(@user, @password).should be_true
slmc.admission_search(:pin => @@pin)
# slmc.click("link=Update Admission",:wait_for => :page);
slmc.click("link=Update Patient Info",:wait_for => :page);
@@pin = slmc.mycreate_new_patient(@patient1.merge(:new => false))
#slmc.click("xpath=(//input[@name='action'])[3]",:wait_for => :page);
#slmc.click("xpath=(//input[@name='action'])[2]",:wait_for => :page);
    puts @@pin
        Database.connect
        a =  "SELECT COUNT(*) FROM SLMC.TXN_PATMAS WHERE PIN ='#{@@pin}'"
        b =  "SELECT COUNT(*) FROM SLMC.TXN_PATMAS_ADDL WHERE PIN ='#{@@pin}'"
        c = "SELECT COUNT(*) FROM SLMC.TXN_PATMAS_ADDR WHERE PIN ='#{@@pin}'"
        d = "SELECT COUNT(*) FROM SLMC.TXN_PATMAS_CONTACT WHERE PIN ='#{@@pin}'"
        e = "SELECT COUNT(*) FROM SLMC.TXN_PATMAS_ID WHERE PIN ='#{@@pin}'"
        f = "SELECT COUNT(*) FROM SLMC.TXN_PATMAS_RELATIONS WHERE PIN ='#{@@pin}'"
        g = "SELECT COUNT(*) FROM SLMC.TXN_PATMAS_SPOUSE WHERE PIN ='#{@@pin}'"
        #q = "select RB_TRANS_NO from TXN_PBA_ROOM_BED_TRANS where RB_TRANS_NO = (select MAX(RB_TRANS_NO) from TXN_PBA_ROOM_BED_TRANS)"
        aa = Database.select_statement a
        bb = Database.select_statement b
        cc = Database.select_statement c
        dd = Database.select_statement d
        ee = Database.select_statement e
        ff = Database.select_statement f
        gg = Database.select_statement g
        aa = aa.to_i
        bb = bb.to_i
        cc = cc.to_i
        dd = dd.to_i
        ee = ee.to_i
        ff = ff.to_i
        gg = gg.to_i

        aa.should == 1
        bb.should == 1
        cc.should >= 1
        dd.should >= 1
        ee.should >= 1
        ff.should >= 1
        gg.should >= 1
        Database.logoff
end
  it "EDIT ADMITTED PATIENT - FILL OUT ALL FIELDS" do
        slmc.login(@user, @password).should be_true
        slmc.admission_search(:pin => @@pin)
        slmc.update_admission(:admission_type =>"WELLNESS",:conf_code => "RESTRICTED",:diagnosis => "010002",:save => true)
        visit_no = slmc.get_visit_number_using_pin(@@pin)
          Database.connect
        a =  "SELECT * FROM SLMC.TXN_PATMAS WHERE PIN ='#{@@pin}'"
        b =  "SELECT * FROM SLMC.TXN_PATMAS_ADDL WHERE PIN ='#{@@pin}'"
        c = "SELECT * FROM SLMC.TXN_PATMAS_ADDR WHERE PIN ='#{@@pin}'"
        d = "SELECT * FROM SLMC.TXN_PATMAS_CONTACT WHERE PIN ='#{@@pin}'"
        e = "SELECT * FROM SLMC.TXN_PATMAS_ID WHERE PIN ='#{@@pin}'"
        f = "SELECT * FROM SLMC.TXN_PATMAS_RELATIONS WHERE PIN ='#{@@pin}'"
        g = "SELECT * FROM SLMC.TXN_PATMAS_SPOUSE WHERE PIN ='#{@@pin}'"
        #q = "select RB_TRANS_NO from TXN_PBA_ROOM_BED_TRANS where RB_TRANS_NO = (select MAX(RB_TRANS_NO) from TXN_PBA_ROOM_BED_TRANS)"
        aa = Database.select_statement a
        bb = Database.select_statement b
        cc = Database.select_statement c
        dd = Database.select_statement d
        ee = Database.select_statement e
        ff = Database.select_statement f
        gg = Database.select_statement g
        aa.should_not == nil
        bb.should_not == nil
        cc.should_not == nil
        dd.should_not == nil
        ee.should_not == nil
        ff.should_not == nil
        gg.should_not == nil
        Database.logoff

  end
end

  