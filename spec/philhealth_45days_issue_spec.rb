require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'ruby-plsql'

describe "Philhealth 45days issue" do
	
  attr_reader :selenium_driver
  alias :slmc :selenium_driver

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

  it "should desc" do
        @patient1 = Admission.generate_data(:not_senior => true)
        @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient1[:age])
        @@discount_amount = (@@room_rate * @@promo_discount)
        @@room_discount = @@room_rate - @@discount_amount


        slmc.login(@user, @password)
        slmc.admission_search(:pin => "Test")
        @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
        #@@pin1 = "1210068782"
        slmc.admission_search(:pin => @@pin1).should be_true
        slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
          :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."

        puts @@pin1
        
        sleep 40
        days_to_adjust = 3
        Database.connect
                 q = "select  VISIT_NO from SLMC.TXN_ADM_ENCOUNTER where PIN = '#{@@pin1}'"
                 vn = Database.select_all_rows q
        Database.logoff
        vn = vn[0]
        d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
        my_set_date = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s
        puts "my_set_date #{my_set_date}"
        plsql.connection = Database.connect
        a = plsql.slmc.sproc_doom(vn,my_set_date,4 ,'P')
        plsql.logoff
        puts a

  end
  it"Inpdatient - Admit - Compute Philhealth " do
     @patient1 = Admission.generate_data
    slmc.login(@user, @password)
    slmc.admission_search(:pin => "Test")
    @@pin2 = slmc.create_new_patient(@patient1).gsub(' ', '')
  #  @@pin1 = "1210068782"
    slmc.admission_search(:pin => @@pin2).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."

    slmc.login(@gu_user_0287, @password)
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin2)
    @drugs1.each do |item, q|
                  slmc.search_order(:description => item, :drugs => true).should be_true
                  slmc.add_returned_order(:drugs => true, :description => item,:quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary1.each do |item, q|
                  slmc.search_order(:description => item, :ancillary => true).should be_true
                  slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies1.each do |item, q|
                  slmc.search_order(:description => item, :supplies => true).should be_true
                  slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_general_units_page
    slmc.nursing_gu_search(:pin => @@pin2)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@pin2, :diagnosis => "A91.0", :no_pending_order => true, :pf_amount => "3000", :save => true).should be_true
    puts @@pin2

    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "11720", :compute => true)
    slmc.ph_save_computation.should be_true
    @@mycase_rate =  "11720"
     Database.connect
            t = "SELECT PF_AMOUNT FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
            pf = Database.select_last_statement t
     Database.logoff
     Database.connect
            t = "SELECT RATE  FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
            rate = Database.select_last_statement t
     Database.logoff
      puts rate

      puts pf
      pf = pf.to_i
      rate = rate.to_i
      @@total_actual_benefit_claim = (rate - pf )#REF_PBA_PH_CASE_RATE.CASE_RATE_NO = '5381'
      mm = @@ph1[:total_actual_benefit_claim].to_i
      puts mm
      ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
####### Verify PF
####### Click Skip philhealth
####### click skip dicount
####### Verify payment page

  end
  
  
end

