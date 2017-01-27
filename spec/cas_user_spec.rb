require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'ruby-plsql'


describe "Cas_user" do
  

  before(:all) do
     @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    #username
    @user = "adm1"  #"billing_spec_user3"  #admission_login#
    @pba_user = "ldcastro" #"sel_pba7"
    @or_user =  "slaquino"     #"or21"
    @oss_user = "jtsalang"  #"sel_oss7"
    @dr_user = "jpnabong" #"sel_dr4"
    @er_user =  "jtabesamis"   #"sel_er4"
    @wellness_user = "ragarcia-wellness" # "sel_wellness2"
    @gu_user_0287 = "gycapalungan"

    

    @@room_rate = 4167.0


    @drugs1 =  {"040004334" => 1}
    @ancillary1 = {"010000003" => 1}
    @supplies1 = {"080200000" => 1}

    @password = "123qweuser"
  end
  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Update Password " do
 Database.connect
        t = "SELECT SLMC_CAS.CTRL_APP_USER FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
        pf = Database.select_last_statement t
 Database.logoff
slmc.login(@user, @password)
#slmc.open "/admin/AdminController"
sleep 3
slmc.type "id=txtEmpNo", emp_id
slmc.click "css=i.glyphicon.glyphicon-search"
sleep 20
slmc.type "id=txtEMail", email
sleep 3
slmc.click "//div[@id='userInfo']/div[2]/div[4]/div/div/span/i"
sleep 3
slmc.type "id=orgSrc", "0009"
sleep 3
slmc.click "//div[@id='dvLst']/div[48]/label"
sleep 3
slmc.type "id=txtNewPass", "qweuser123"
slmc.type "id=txtConPass", "qweuser123"
slmc.click "css=button.btn.btn-primary"
sleep 10

slmc.type "id=txtEmpNo", emp_id
slmc.click "css=i.glyphicon.glyphicon-search"
sleep 20
if QC == true
      slmc.click "name=chk_h_loc"
elsif GC == true
    slmc.click "xpath=(//input[@name='chk_h_loc'])[2]"
else
      slmc.click "name=chk_h_loc"
      slmc.click "xpath=(//input[@name='chk_h_loc'])[2]"
end

slmc.click "link=SYSTEM ACCESS RIGHTS"
slmc.add_selection "id=availableSysDListI", "label=Healthcare System GC"
slmc.click "css=#systemAccess > div > div > button.btn.btn-default"
slmc.click "css=#selectedSysDListI > option"
slmc.click "id=btnSave"
slmc.wait_for_page_to_load "30000"
    
  end
    it "Change Password" do
    
    
    
  end
end

