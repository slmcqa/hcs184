# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'
require 'ruby-plsql'
require 'rpdfbox'



describe "Philhealth_new_feature" do
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

    @doctors = ["6726","0126","6726","0126"]
    
    @@room_rate = 4167.0

    @patient1 = Admission.generate_data
    @patient2 = Admission.generate_data
    
    @drugs1 =  {"040004334" => 1}
    @ancillary1 = {"010000003" => 1}
    @supplies1 = {"080200000" => 1}

    @password = "123qweuser"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Feature Enhancement #11681 - Philhealth Multiple Session: 2nd case Order Deatils, Philhealth claim and saving of data as required in the Philhealth Claims Report " do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@pin = (slmc.oss_outpatient_registration(@patient1)).gsub(' ','').should be_true
    puts @@pin

    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    @ancillary = {"010001823" => 2,"010001636" => 2}
    #add all items to be ordered
    @@orders =  @ancillary.merge(@drugs1)
    n = 0
    @@orders.each do |item, q|
              slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
              n += 1
    end

    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','')
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin)
    slmc.click_philhealth_link.should be_true

    sleep 2
    @@visit_no = slmc.get_visit_number_using_pin(@@pin) #sometimes submitting or/ci hang
    @@or_no = slmc.access_from_database(:what => "OR_NUMBER", :table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no)

    Database.connect
        a =  "SELECT ORDER_DTL_NO  FROM TXN_OM_ORDER_DTL JOIN TXN_OM_ORDER_GRP ON TXN_OM_ORDER_DTL.ORDER_GRP_NO = TXN_OM_ORDER_GRP.ORDER_GRP_NO WHERE VISIT_NO = '#{@@visit_no}'"
        @@order_dtl_no = Database.select_all_rows a

    Database.logoff

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
    sleep 3
    slmc.oss_rvu(:rvu_key => "77401", :rvu_key2 => "90935", :diagnosis => "A00").should be_true
    slmc.click_add_reference(:pin => @@pin,:reference_no=>@@or_no).should be_true
    sleep 3
    slmc.is_text_present(@@order_dtl_no[0]).should be_true
    sleep 3
    slmc.is_text_present(@@order_dtl_no[1]).should be_true
    sleep 3
    slmc.is_text_present(@@order_dtl_no[2]).should be_true
    sleep 3
    slmc.is_text_present(@@order_dtl_no[3]).should be_true
    x = 0
    n = @@order_dtl_no.length
    @@order_dtl_no.each do |item, q|
              puts @@order_dtl_no[x]
              slmc.is_text_present(@@order_dtl_no[x]).should be_true
              n -= 1
              x += 1
    end


    @@or_ph2[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
   #incomplete
   #need to check the claim rate





  end
  it "Feature Enhancement #12507 - Philhealth: Inpatient Multiple Session and CF2 Enhancement" do
####### CREATE AND ADMIT ################################
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(Admission.generate_data)
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
             :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."


      days_to_adjust = 2
      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
      my_set_date = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s
      puts "my_set_date #{my_set_date}"
      Database.connect
             pin  = "SELECT MAX(VISIT_NO) FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin}'"
             @@visit_no = Database.select_statement pin
             visit_no = @@visit_no
             plsql.connection = Database.connect
                      a =  plsql.slmc.sproc_doom("#{visit_no}","#{my_set_date}",3,'P')
             plsql.logoff
      Database.logoff
      puts a
###################### ORDER ITEMS IN GENERAL UNIT #################################################################
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
                slmc.search_order(:description => item, :drugs => true)
                slmc.add_returned_order(:drugs => true, :description => item,
                  :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "5979")
    end
    @ancillary1.each do |item, q|
                slmc.search_order(:description => item, :ancillary => true)
                slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126")
    end
    @supplies1.each do |item, q|
                slmc.search_order(:description => item, :supplies => true)
                slmc.add_returned_order(:supplies => true, :description => item, :add => true)
    end
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :supplies => true, :ancillary => true, :orders => "multiple").should == 3
    sleep 3
    slmc.confirm_validation_all_items.should be_true

########################## CLINICALLY DISCHARGE ############################################################################################

    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true

########################## STANDARD DISCHARGE ############################################################################################
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    puts @@pin

#################################### PHILHEALTH #####################################################################
    @@ph1 = slmc.philhealth_computation(:rvu_code => "77401", :multiple1 => true, :no_of_session => 3, :case_rate_type2 =>  "SURGICAL",
                    :case_rate2 => "90935", :multiple2 => true, :no_of_session2 => 2, :claim_type => "ACCOUNTS RECEIVABLE", :case_rate_type => "SURGICAL",
                    :diagnosis => "CHOLERA",:case_rate => "A90" , :compute => true)
    slmc.ph_save_computation
     claim_rate1 = 2200
     no_session1 = 3
     claim_rate2 = 3500
     no_session2 = 2
    @@total_actual_benefit_claim = (claim_rate1 * no_session1  + claim_rate2 * no_session2)
    @@ph1[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))

  end
  it "Feature Enhancement #12262 - Philhealth: Waiver for directly filed Philhealth claims" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(Admission.generate_data)
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
             :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."

###################### ORDER ITEMS IN GENERAL UNIT #################################################################
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
                slmc.search_order(:description => item, :drugs => true)
                slmc.add_returned_order(:drugs => true, :description => item,
                  :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "5979")
    end
    @ancillary1.each do |item, q|
                slmc.search_order(:description => item, :ancillary => true)
                slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126")
    end
    @supplies1.each do |item, q|
                slmc.search_order(:description => item, :supplies => true)
                slmc.add_returned_order(:supplies => true, :description => item, :add => true)
    end
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :supplies => true, :ancillary => true, :orders => "multiple").should == 3
    sleep 3
    slmc.confirm_validation_all_items.should be_true

########################## CLINICALLY DISCHARGE ############################################################################################

    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true

########################## STANDARD DISCHARGE ############################################################################################
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    puts @@pin
#################################### PHILHEALTH #####################################################################
    @@ph1 = slmc.philhealth_computation(:rvu_code => "10060", :claim_type => "REFUND", :case_rate_type => "SURGICAL",
                    :diagnosis => "CHOLERA",:case_rate => "A90" , :compute => true)
    slmc.ph_save_computation
    sleep 6
    slmc.click "id=btnPrint"
    sleep 6
    slmc.open("/report/philHealthClaimReport.html")
    sleep 6
    slmc.click "id=download"
    sleep 6
    text = RPDFBox::TextExtraction.get_text_all("C:\\Users\\15239\\Downloads\\document.pdf")
  puts text
  end
end
