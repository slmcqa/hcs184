#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
require 'spec_helper'
require 'ruby-plsql'

describe"Issues_from_161f" do
  attr_reader :selenium_driver
  alias :slmc :selenium_driver
  before(:all) do
     @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    #username
    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
    #@pba_user = "ldcastro" #"sel_pba7"
    @pba_user = "pba1" #"sel_pba7"
    @or_user =  "slaquino"     #"or21"
    @oss_user = "jtsalang"  #"sel_oss7"
    @dr_user = "jpnabong" #"sel_dr4"
    @er_user =  "jtabesamis"   #"sel_er4"
    @wellness_user = "ragarcia-wellness" # "sel_wellness2"
    @gu_user_0287 = "gycapalungan"
    @inhouse_user = "sel_inhouse1"

    @doctors = ["6726","0126","6726","0126"]
    @@room_rate = 4167.0


    @drugs1 =  {"040004334" => 1}
    @ancillary1 = {"010001634" => 1}
    @supplies1 = {"080200000" => 1}

    @drugs2 =  {"040010009" => 1}
    @ancillary2 = {"010002840" => 1}
    @supplies2 = {"269401035" => 1}

    @ancillary3 = {"010001634" => 1,"010002840" => 1}

    @password = "123qweuser"
  end
  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
  it "4728 - Philhealth: DAS OSS/Special Ancillary Unit - Incorrect Philhealth Claim being computed for the additional surgical case rates" do
            ########                    DAS OSS
            ########                    1. login as das user
            ########                    2. search patient
            ########                    3. click outpatient order button
            ########                    4. click philhealth checkbox
            ########                    5. fill-in the guarantors tab
            ########                    6. on the orders tab, search for imrt (010001634) item, fill in other fields and click add button
            ########                    7. on the philhealth tab,
            ########                    - choose surgical case rate type
            ########                    - search for rvu code 77418 in the case rate field
            ########                    - search for rvu code 77418 in the operation field
            ########                    - fill up other required fields
            ########                    8. click the compute claims button
            ########                    result: the philhealth claim is computed based on the benefit claim of the ordered item under ordinary case type.
            ########                    expected: the philhealth claim should show a total benefit summary of 4,000.00
            ########                    - reference is the data in ref_pba_ph_case_rate for rvu code 77418;
            ########                    hospital bill = rate (5,680.00) - pf amount (1,680.00) = 4,000.00
            @ph_patient = Admission.generate_data
            slmc.login("sel_oss5", @password).should be_true
            slmc.go_to_das_oss
            slmc.patient_pin_search(:pin => "test")

            slmc.click_outpatient_registration.should be_true
            @@pin = (slmc.oss_outpatient_registration(@ph_patient)).gsub(' ','').should be_true
            puts @@pin            
            slmc.go_to_das_oss
            slmc.patient_pin_search(:pin => @@pin)
            slmc.click_outpatient_order(:pin => @@pin).should be_true

            #add all items to be ordered
            @@orders =  @ancillary1.merge(@supplies1).merge(@drugs1)
            n = 0
            @@orders.each do |item, q|
                      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[0])
                      n += 1
            end
            slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
            slmc.oss_patient_info(:philhealth => true)
            @@ph = slmc.oss_input_philhealth(:case_type => "INTENSIVE CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "77418", :compute => true)
            @@total_actual_benefit_claim = "4000"
            @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
            puts @@ph[:total_actual_benefit_claim]
            amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','')
            slmc.oss_add_payment(:amount => amount, :type => "CASH")
            (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."

            ########          Special Ancillary
            ########          1. login as das user with Ancillary SU role and unit is under Ambulatory Care
            ########          2. click patient search link
            ########          3. search patient
            ########          4. select outpatient clinical order then click submit button
            ########          5. order for drugs, supplies and ancillary items, add to cart and validate items
            ########          5. complete the information on patient's guarantor
            ########          6. in the pf encoding page, set pf type for patient's referring doctors to c/o HMO/PPO
            ########          7. in the hospital bills and pf settlement page,
            ########          - click philhealth checkbox
            ########          - choose surgical case rate type
             ########          - search for rvu code 96408 in the case rate field
            ########          - search for rvu code 96408 in the operation field
            ########          - fill up other required fields
            ########          8. click the compute claims button
            ########          result: the philhealth claim is computed based on the benefit claim of the ordered items under ordinary case type.
            ########
            ########          expected: the philhealth claim should show a total benefit summary of 5,600.00
            ########          - reference is the data in ref_pba_ph_case_rate for rvu code 96408;
            ########          hospital bill = rate (7,280) - pf amount (1,680.00) = 5,600.00

            ########           "//html/body/div/div[2]/div[2]/div[5]/table/tbody/tr/td[10]/input"


            @su_patient = Admission.generate_data
            sleep 6
            slmc.login("das_su", @password).should be_true
            slmc.go_to_ancillary_su
            slmc.click("link=Patient Search", :wait_for =>:page)
            slmc.patient_pin_search(:pin => "test")
            slmc.click_outpatient_registration.should be_true
            @@pin = (slmc.oss_outpatient_registration(@su_patient)).gsub(' ','').should be_true
            puts @@pin
            slmc.login("das_su", @password).should be_true
            slmc.go_to_ancillary_su
            slmc.click("link=Patient Search", :wait_for =>:page)
            slmc.patient_pin_search(:pin =>@@pin)
            slmc.select "id=userAction#{@@pin}", "label=Outpatient Clinical Order"
            sleep 10
#            slmc.click("//html/body/div/div[2]/div[2]/div[5]/table/tbody/tr/td[10]/input")
             if slmc.is_element_present("css=td.ctrlButtons.over > input[type=\"button\"]")
                  slmc.click "css=td.ctrlButtons.over > input[type=\"button\"]" #:wait_for => :page 
             else
               slmc.click "//html/body/div[1]/div[2]/div[2]/div[6]/table/tbody/tr/td[10]/input"
             end
            
            sleep 10



            sleep 6

            slmc.is_text_present("Add New Order").should be_true
            @drugs2.each do |item, q|
                          slmc.search_order(:description => item, :drugs => true).should be_true
                          slmc.add_returned_order(:drugs => true, :description => item,:quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
            end
            @ancillary2.each do |item, q|
                          slmc.search_order(:description => item, :ancillary => true).should be_true
                          slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
            end
            @supplies2.each do |item, q|
                          slmc.search_order(:description => item, :supplies => true).should be_true
                          slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
            end
            slmc.submit_added_order(:validate => false, :username => "sel_0287_validator").should be_true
            slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
            slmc.confirm_validation_all_items.should be_true

            slmc.click "link=Add/Edit Guarantor Info"
            sleep 4
            slmc.click "id=addLink"
            sleep 4
            slmc.click "name=_submit"
            sleep 4
            slmc.click "css=input[type=\"submit\"]"
            sleep 6
            slmc.is_text_present("The Patient Info was updated.").should be_true
            slmc.click("link=PF Encoding", :wait_for =>:page)
            slmc.click "id=admDoctorRadioButton0"
            sleep 3
            slmc.click "id=btnAddPf"
            sleep 3
            slmc.select "id=pfTypeCode", "label=C/O HMO/PPO/SLMC Packages/Outpatient"
            sleep 3
            slmc.click "css=option[value=\"PFI07\"]" if slmc.is_element_present("css=option[value=\"PFI07\"]")
            sleep 3
            slmc.type "id=pfAmountInput", "1000"
            sleep 3
            slmc.click "id=btnAddPf"
            sleep 3
            slmc.click("name=action", :wait_for =>:page)
            slmc.is_text_present("PF successfully saved.").should be_true

            slmc.click("link=Hospital Bills and PF Settlement", :wait_for =>:page)
            slmc.oss_patient_info(:philhealth => true)
            @@mycase_rate =  "96408"
            @@ph = slmc.oss_input_philhealth(:case_type => "INTENSIVE CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => @@mycase_rate, :compute => true)

            Database.connect
                    t = "SELECT TO_CHAR(PF_AMOUNT) FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
                    pf = Database.select_last_statement t
            Database.logoff
            Database.connect
                    t = "SELECT TO_CHAR(RATE)  FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
                    rate = Database.select_last_statement t
            Database.logoff
             pf = pf.to_i
             rate = rate.to_i
             @@total_actual_benefit_claim = rate - pf
             @@pf_benefit_claim = pf
             @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
            slmc.ancillary_su_payment(:cash => true).should == "The ORWITHCI was successfully updated with printTag = 'Y'."

  end
  it "4167 - Philhealth: Accounts Receivable Claim is not being saved to Final during Standard discharge process" do
            @patient1 = Admission.generate_data
            @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient1[:age])
            @@discount_amount = (@@room_rate * @@promo_discount)
            @@room_discount = @@room_rate - @@discount_amount


            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."

            slmc.login(@gu_user_0287, @password)
            slmc.go_to_general_units_page
            slmc.go_to_adm_order_page(:pin => @@pin1)
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
            slmc.nursing_gu_search(:pin => @@pin1)
            @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
            @@visit_no1 = slmc.clinically_discharge_patient(:pf_type => "COLLECT",:pin => @@pin1, :diagnosis => "A91.0", :no_pending_order => true, :pf_amount => "6400", :save => true).should be_true
            puts @@visit_no1
            puts @@pin1

            slmc.login(@pba_user, @password)
            slmc.go_to_patient_billing_accounting_page
            slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
            slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
            slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
            slmc.skip_update_patient_information.should be_true
            slmc.skip_room_and_bed_cancelation.should be_true
            @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "11444", :compute => true)
            slmc.ph_save_computation.should be_true
            sleep 3
            slmc.is_text_present("FINAL").should be_true

  end
  it "3249 - Admission:In Room-Transfer all Inactive Room Charge still appears in the drop-down" do
          @patient1 = Admission.generate_data
            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."

            slmc.login(@gu_user_0287, @password)
            slmc.go_to_general_units_page
            sleep 3
            slmc.go_to_gu_room_tranfer_page(:pin => @@pin1)
            sleep 3
		  select "id=optRequestStatus", "label=New" if slmc.is_element_present("id=optRequestStatus")

            slmc.type "id=txtRemarks", "asdas"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)

            slmc.login(@user, @password)
            slmc.go_to_admission_page
            sleep 3

            slmc.click "id=roomTransferImg"
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Update Request Status"
            sleep 3
            slmc.click "css=option[value=\"update\"]"
            sleep 3
            slmc.select "id=optRequestStatus", "label=For Room Transfer"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)

            slmc.login(@gu_user_0287, @password)
            slmc.go_to_general_units_page
            slmc.go_to_gu_room_tranfer_page(:pin => @@pin1)
            slmc.click "id=roomTransferImg"
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Update Request Status"
            sleep 3
            slmc.click "css=option[value=\"update\"]"
            sleep 3
            slmc.select "id=optRequestStatus", "label=Physically Transferred"
            sleep 3
            slmc.click "css=option[value=\"RQS03\"]"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)

            slmc.login(@user, @password)
            slmc.go_to_admission_page
            slmc.click "id=roomTransferImg"
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Transfer Room Location"
            sleep 3
            slmc.select "id=optTransferType", "label=NURSING UNIT TRANSFER"
            sleep 3

           inactive_charge = "DELUXE PRIVATE (PC)"
           my_count =  slmc.get_xpath_count('//*[@id="roomChargeCode"]')
           my_count = my_count.to_i
           puts my_count
           while my_count !=0
                     if  my_count == 1
                               selected_rb_charge = slmc.get_text("//html/body/div/div[2]/div[2]/div[6]/div[2]/div[3]/select/option")
                     else
                               selected_rb_charge = slmc.get_text("//html/body/div/div[2]/div[2]/div[6]/div[2]/div[3]/select/option[#{my_count}]")
                     end
                     if inactive_charge == selected_rb_charge
                       return false
                       my_count = 0
                     else
                            my_count = my_count - 1
                     end
           end

  end
  it "2926 - DAS-OSS and SU:View Information button Be Visible To All Patient" do
            @ph_patient = Admission.generate_data
            slmc.login("sel_oss5", @password).should be_true
            slmc.go_to_das_oss
            slmc.patient_pin_search(:pin => "test")
            slmc.click_outpatient_registration.should be_true
            @@pin = (slmc.oss_outpatient_registration(@ph_patient)).gsub(' ','').should be_true
            puts @@pin

            Database.connect
                          a =  "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PATIENT_TYPE = 'O' and ADM_FLAG = 'Y'"
                          b = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PATIENT_TYPE = 'I' and ADM_FLAG = 'Y'"
                          c = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PATIENT_TYPE = 'I' and ADM_FLAG = 'N'"
                          d = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PATIENT_TYPE = 'O' and ADM_FLAG = 'N'"
                          e = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PATIENT_TYPE = 'O' and ADM_FLAG IS NULL"

                          a1 = Database.select_last_statement a
                          b1 = Database.select_last_statement b
                          c1 = Database.select_last_statement c
                          d1 = Database.select_last_statement d
                          e1 = Database.select_last_statement e
            Database.logoff
            slmc.login("sel_oss5", @password).should be_true
            slmc.go_to_das_oss
            slmc.patient_pin_search(:pin => @@pin)
            slmc.click "id=viewPatientInformationBtn#{@@pin}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => a1)
            slmc.click "id=viewPatientInformationBtn#{a1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => b1)
            slmc.click "id=viewPatientInformationBtn#{b1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => c1)
            slmc.click "id=viewPatientInformationBtn#{c1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => d1)
            slmc.click "id=viewPatientInformationBtn#{d1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => e1)
            slmc.click "id=viewPatientInformationBtn#{e1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
##########  Special Unit ###################################################
            slmc.login(@dr_user, @password).should be_true
            slmc.go_to_outpatient_nursing_page
            slmc.patient_pin_search(:pin => @@pin)
            slmc.click "id=viewPatientInformationBtn#{@@pin}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => a1)
            slmc.click "id=viewPatientInformationBtn#{a1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => b1)
            slmc.click "id=viewPatientInformationBtn#{b1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => c1)
            slmc.click "id=viewPatientInformationBtn#{c1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => d1)
            slmc.click "id=viewPatientInformationBtn#{d1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
            slmc.patient_pin_search(:pin => e1)
            slmc.click "id=viewPatientInformationBtn#{e1}"
            slmc.click "id=closeMpiPatientPreviewBtn"
  end
  it "2899 - Inactive items can view in SU-Checklist Order, GU-Order page and DAS OSS -Outpatient Order" do
           @drugs2 =  {"044813997" => 1}
           @ancillary2 = {"010002394" => 1}
           @supplies2 = {"010002507" => 1}

            @ph_patient = Admission.generate_data
           slmc.login("sel_oss5", @password).should be_true
            slmc.go_to_das_oss
            slmc.patient_pin_search(:pin => "test")
            slmc.click_outpatient_registration.should be_true
            @@pin = (slmc.oss_outpatient_registration(@ph_patient)).gsub(' ','').should be_true
            puts @@pin
           slmc.login("sel_oss5", @password).should be_true
            slmc.go_to_das_oss
            slmc.patient_pin_search(:pin => @@pin)
            slmc.click_outpatient_order(:pin => @@pin).should be_true
            @@orders =  @ancillary2.merge(@supplies2).merge(@drugs2)
            n = 0
            @@orders.each do |item, q|
                      slmc.oss_order(:check_item => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
                      slmc.is_text_present("0 item(s). Displaying 0 to 0.").should be_true
                      slmc.click("//html/body/div/div[2]/div[2]/form[2]/div[8]/div/div/div[2]/div/input[4]")

                      n += 1
            end

    ################## CHECKLIST ORDER ############
            @or_patient = Admission.generate_data
            slmc.login(@or_user, @password).should be_true
            @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F')).gsub(' ', '')
             slmc.login(@or_user, @password).should be_true
            slmc.go_to_occupancy_list_page
            slmc.patient_pin_search(:pin => @@or_pin)
            sleep 3
            slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
            @drugs2.each do |item, q|
                        slmc.check_order(:description => item, :drugs => true)
            end
            @ancillary2.each do |item, q|
                        slmc.check_order(:description => item, :ancillary => true).should be_false
            end
            @supplies2.each do |item, q|
                        slmc.check_order(:description => item, :supplies => true).should be_false
            end

            slmc.go_to_occupancy_list_page
            slmc.patient_pin_search(:pin => @@or_pin)
            slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
            slmc.check_service(:procedure => true, :description => "BLOOD SUGAR MONITORING")
            slmc.is_text_present("0 items.")

  end
  it "2740 - Endorsement tagging code review and query improvement" do
           @patient1 = Admission.generate_data
            slmc.login("adm1", @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login("adm1", @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
            slmc.admission_search(:pin => @@pin1)
            sleep 3
            slmc.click("link=Endorsement Tagging",:wait_for => :page)
            slmc.click "name=btnAddNew"
            slmc.select "id=add_endorsementType", "label=SPECIAL ARRANGEMENTS"
            slmc.click "css=#add_endorsementType > option[value=\"END6\"]"
            slmc.select "id=add_endorsementType", "label=UNSETTLED ACCOUNTS"
            #page.click "css=#add_endorsementType > option[value=\"END8\"]"
            slmc.type "id=endorsement_textarea", "selenuim test"
            slmc.add_selection "id=destination_select", "label=BILLING"
            slmc.click("name=btnSave", :wait_for => :page)
 #           slmc.login("sel_pba1", @password)

  end
  it "2718 - In-House Collection: Include validation in creating new endorsement" do
          @patient1 = Admission.generate_data
            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
            puts @@pin1
            slmc.admission_search(:pin => @@pin1)
            slmc.click("link=Endorsement Tagging", :wait_for =>:page)
            slmc.click "name=btnAddNew"
            sleep 2
            slmc.select "id=add_endorsementType", "label=SPECIAL ARRANGEMENTS"
            sleep 2
            slmc.click "css=option[value=\"END6\"]"
            sleep 2
            slmc.click "id=endorsement_textarea"
            sleep 2
            slmc.type "id=endorsement_textarea", "sadasdas"
            sleep 2
            slmc.add_selection "id=destination_select", "label=BILLING"
            sleep 2
            slmc.click("name=btnSave", :wait_for =>:page)
            slmc.is_text_present("SPECIAL ARRANGEMENTS").should be_true
            Database.connect
                    a =  "SELECT  ENDORSEMENT_TYPE FROM SLMC.TXN_ENDORSEMENT_HDR WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                    a1 = Database.select_last_statement a
            Database.logoff
            a1.should == "END6"
            Database.connect
                    a = "SELECT * FROM TXN_ENDORSEMENT_HDR WHERE ENDORSEMENT_TYPE IS NULL"
                    a1 = Database.my_select_last_statement a
            Database.logoff
            a1.should == nil
  end
  it "6338 - Initial Creation of inpatient " do
           @patient1 = Admission.generate_data
            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
            puts @@pin1
            sleep 3
 #            @@pin1 = "1410076100"
            Database.connect
                      a = "SELECT VISIT_NO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      b = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}'"
                      c = "SELECT VISIT_NO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                      d = "SELECT ROOMNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      e = "SELECT ROOMNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                      f = "SELECT BEDNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      g = "SELECT BEDNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                      h = "SELECT NURSING_UNIT  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      i = "SELECT NURSING_UNIT FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                      j = "SELECT CONFIDENTIAL FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      k = "SELECT CONFIDENTIAL FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}'"
                      l  = "SELECT REDTAG_FLAG, DEATH_TYPE, DEATH_FLAG, ENDORSEMENT_FLAG, ROOMTRAN_RQST_STATUS, PACKAGE_RATE_NO, DIET_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"



                      a1 = Database.my_select_last_statement a
                      b1 = Database.my_select_last_statement b
                      c1 = Database.my_select_last_statement c
                      d1 = Database.my_select_last_statement d
                      e1 = Database.my_select_last_statement e
                      f1 = Database.my_select_last_statement f
                      g1 = Database.my_select_last_statement g
                      h1 = Database.my_select_last_statement h
                      i1 = Database.my_select_last_statement i
                      j1 = Database.my_select_last_statement j
                      k1 = Database.my_select_last_statement k
                      l1 = Database.select_all_statement l


                      a1.should_not  nil  #VISIT NUMBER IN OCCUPANCY LIST TABLE
                      a1.should  == c1   #VISIT NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      b1.should_not  nil # PIN IN ADM ENCOUTER TABLE
                      d1.should  == e1 #ROOM NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      f1.should  == g1  #BEDNUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      h1.should  == i1  #NURSING_UNIT IN OCCUPANCY LIST AND ADM IN TABLE
                      j1.should  == k1  #CONFIDENTIAL IN OCCUPANCY LIST AND ADM IN TABLE
                      l1[0].should == 'N' || nil
                      l1[1].should == nil
                      l1[2].should == 'N'
                      l1[3].should == 'N'
                      l1[4].should == '-'
                      l1[5].should == nil
                      l1[6].should == "Y"
                      l1[7].should == 'A'
            Database.logoff
                   sleep 3
########################################################################################################################################
####################################### admitting a patient as ON-QUEUE #####################################################################
#######################################################################################################################################
            @patient1 = Admission.generate_data
            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:on_queue => true, :account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
              puts @@pin1
            Database.connect
                        a = "SELECT * FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                        b1 = Database.my_select_last_statement a
                        b1.should nil # PIN IN TXN_OCCUPANCY_LIST TABLE

            Database.logoff
###########################################################################################################################################
############################################ admitting a patient as NEWBORN ADMISSION ##########################################################
###########################################################################################################################################
###########################################################################################################################################
            @dr_patient1 = Admission.generate_data
            slmc.login("jpnabong", @password).should be_true
            @@slmc_mother_pin = (slmc.or_create_patient_record(@dr_patient1.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0170'))).gsub(' ', '')
            slmc.login("jpnabong", @password).should be_true
            sleep 3
            slmc.go_to_outpatient_nursing_page
            slmc.outpatient_to_inpatient(@dr_patient1.merge(:pin => @@slmc_mother_pin, :username => "ldvoropesa", :password => @password,
                :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
            slmc.login("jpnabong", @password).should be_true
            slmc.register_new_born_patient(:pin => @@slmc_mother_pin, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "F",:birth_type => "SINGLE",
              :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,:doctor_name => "ABAD", :rooming_in => true, :save => true)
            l_name = @dr_patient1[:last_name]
            l_name  = (l_name).upcase
            m_name = @dr_patient1[:middle_name]
            m_name  = (m_name).upcase
            Database.connect
                    a = "SELECT PIN FROM SLMC.TXN_PATMAS WHERE UPPER(LASTNAME) = '#{l_name}' AND UPPER(MIDDLENAME) = '#{m_name}' AND UPPER(FIRSTNAME) = 'BABY GIRL'"
                    @@babypin = Database.my_select_last_statement a
            Database.logoff
            puts @@slmc_mother_pin
            puts @@babypin
            Database.connect
                      a = "SELECT VISIT_NO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@slmc_mother_pin}'"
                      b = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@slmc_mother_pin}'"
                      c = "SELECT VISIT_NO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@slmc_mother_pin}')"
                      d = "SELECT ROOMNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@slmc_mother_pin}'"
                      e = "SELECT ROOMNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@slmc_mother_pin}')"
                      f = "SELECT BEDNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@slmc_mother_pin}'"
                      g = "SELECT BEDNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@slmc_mother_pin}')"
                      h = "SELECT NURSING_UNIT  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@slmc_mother_pin}'"
                      i = "SELECT NURSING_UNIT FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@slmc_mother_pin}')"
                      j = "SELECT CONFIDENTIAL FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@slmc_mother_pin}'"
                      k = "SELECT CONFIDENTIAL FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@slmc_mother_pin}'"
                      l  = "SELECT REDTAG_FLAG, DEATH_TYPE, DEATH_FLAG, ENDORSEMENT_FLAG, ROOMTRAN_RQST_STATUS, PACKAGE_RATE_NO, DIET_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@slmc_mother_pin}'"
                      a1 = Database.my_select_last_statement a
                      b1 = Database.my_select_last_statement b
                      c1 = Database.my_select_last_statement c
                      d1 = Database.my_select_last_statement d
                      e1 = Database.my_select_last_statement e
                      f1 = Database.my_select_last_statement f
                      g1 = Database.my_select_last_statement g
                      h1 = Database.my_select_last_statement h
                      i1 = Database.my_select_last_statement i
                      j1 = Database.my_select_last_statement j
                      k1 = Database.my_select_last_statement k
                      l1 = Database.select_all_statement l


                      a1.should_not  nil  #VISIT NUMBER IN OCCUPANCY LIST TABLE
                      a1.should  == c1   #VISIT NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      b1.should_not  nil # PIN IN ADM ENCOUTER TABLE
                      d1.should  == e1 #ROOM NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      f1.should  == g1  #BEDNUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      h1.should  == i1  #NURSING_UNIT IN OCCUPANCY LIST AND ADM IN TABLE
                      j1.should  == k1  #CONFIDENTIAL IN OCCUPANCY LIST AND ADM IN TABLE
                      l1[0].should == 'N'
                      l1[1].should == nil
                      l1[2].should == 'N'
                      l1[3].should == 'N'
                      l1[4].should == '-'
                      l1[5].should == nil
                      l1[6].should == "Y"
                      l1[7].should == 'A'
            Database.logoff
            Database.connect
                      a = "SELECT VISIT_NO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@babypin}'"
                      b = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@babypin}'"
                      c = "SELECT VISIT_NO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@babypin}')"
                      d = "SELECT ROOMNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@babypin}'"
                      e = "SELECT ROOMNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@babypin}')"
                      f = "SELECT BEDNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@babypin}'"
                      g = "SELECT BEDNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@babypin}')"
                      h = "SELECT NURSING_UNIT  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@babypin}'"
                      i = "SELECT NURSING_UNIT FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@babypin}')"
                      j = "SELECT CONFIDENTIAL FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@babypin}'"
                      k = "SELECT CONFIDENTIAL FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@babypin}'"
                      l  = "SELECT REDTAG_FLAG, DEATH_TYPE, DEATH_FLAG, ENDORSEMENT_FLAG, ROOMTRAN_RQST_STATUS, PACKAGE_RATE_NO, DIET_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@babypin}'"
                      a1 = Database.my_select_last_statement a
                      b1 = Database.my_select_last_statement b
                      c1 = Database.my_select_last_statement c
                      d1 = Database.my_select_last_statement d
                      e1 = Database.my_select_last_statement e
                      f1 = Database.my_select_last_statement f
                      g1 = Database.my_select_last_statement g
                      h1 = Database.my_select_last_statement h
                      i1 = Database.my_select_last_statement i
                      j1 = Database.my_select_last_statement j
                      k1 = Database.my_select_last_statement k
                      l1 = Database.select_all_statement l
                      a1.should_not  nil  #VISIT NUMBER IN OCCUPANCY LIST TABLE
                      a1.should  == c1   #VISIT NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      b1.should_not  nil # PIN IN ADM ENCOUTER TABLE
                      d1.should  == e1 #ROOM NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      f1.should  == g1  #BEDNUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      h1.should  == i1  #NURSING_UNIT IN OCCUPANCY LIST AND ADM IN TABLE
                      j1.should  == k1  #CONFIDENTIAL IN OCCUPANCY LIST AND ADM IN TABLE
                 #     l1[0].should == 'N'
                      l1[1].should == nil
                      l1[2].should == 'N'
                      l1[3].should == 'N'
                      l1[4].should == '-'
                      l1[5].should == nil
                      l1[6].should == "Y"
                      l1[7].should == 'A'
            Database.logoff
#######################################################################################################################################
######################################## Admitting a patient as WELLNESS PATIENT ##########################################################
#######################################################################################################################################
#######################################################################################################################################
            @@package_code = "10000"
            @patient1 = Admission.generate_data
            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1.merge!(:gender => 'M')).gsub(' ', '')

            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:admission_type =>"WELLNESS", :package => "PLAN A MALE", :account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
             puts @@pin1
   #       @@pin1 = "1410076240"
             Database.connect
                                a = "SELECT VISIT_NO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                b = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}'"
                                c = "SELECT VISIT_NO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                                d = "SELECT ROOMNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                e = "SELECT ROOMNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                                f = "SELECT BEDNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                g = "SELECT BEDNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                                h = "SELECT NURSING_UNIT  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                i = "SELECT NURSING_UNIT FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                                j = "SELECT CONFIDENTIAL FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                k = "SELECT CONFIDENTIAL FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}'"
                                l  = "SELECT REDTAG_FLAG, DEATH_TYPE, DEATH_FLAG, ENDORSEMENT_FLAG, ROOMTRAN_RQST_STATUS, PACKAGE_RATE_NO, DIET_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                m = "SELECT PACKAGE_RATE_NO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                n  = "SELECT PACKAGE_RATE_NO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                                o = "SELECT PACKAGE_RATE_NO FROM SLMC.REF_PACKAGE_RATE WHERE PACKAGE_CHARGE = 'PCH03' AND PACKAGE_CODE = '#{@@package_code}'"
                                a1 = Database.my_select_last_statement a
                                b1 = Database.my_select_last_statement b
                                c1 = Database.my_select_last_statement c
                                d1 = Database.my_select_last_statement d
                                e1 = Database.my_select_last_statement e
                                f1 = Database.my_select_last_statement f
                                g1 = Database.my_select_last_statement g
                                h1 = Database.my_select_last_statement h
                                i1 = Database.my_select_last_statement i
                                j1 = Database.my_select_last_statement j
                                k1 = Database.my_select_last_statement k
                                l1 = Database.select_all_statement l
                                o1 = Database.my_select_last_statement o
                                m1 = Database.my_select_last_statement m
                                n1 = Database.my_select_last_statement n

                                a1.should_not  nil  #VISIT NUMBER IN OCCUPANCY LIST TABLE
                                a1.should  == c1   #VISIT NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                                b1.should_not  nil # PIN IN ADM ENCOUTER TABLE
                                d1.should  == e1 #ROOM NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                                f1.should  == g1  #BEDNUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                                h1.should  == i1  #NURSING_UNIT IN OCCUPANCY LIST AND ADM IN TABLE
                                j1.should  == k1  #CONFIDENTIAL IN OCCUPANCY LIST AND ADM IN TABLE
                                l1[0].should == 'N'
                                l1[1].should == nil
                                l1[2].should == 'N'
                                l1[3].should == 'N'
                                l1[4].should == '-'
                                pcode = l1[5]
                                pcode1 = n1
                                pcode  = (pcode).to_s
                                pcode1  = (pcode1).to_s
                                pcode.should == pcode1
                                l1[6].should == "Y"
                                l1[7].should == 'A'
                                o1.should == m1
                                o1.should == n1
              Database.logoff
  end
  it "6338 - Update of Inpatient Adm dtls" do
            slmc.login(@er_user, @password).should be_true
            @@er_pin = slmc.er_create_patient_record(Admission.generate_data(:not_senior => true)).gsub(' ','').should be_true
            slmc.admit_er_patient(:account_class => "INDIVIDUAL", :turn_inpatient  => true)
            puts @@er_pin
            Database.connect
                    a = "SELECT * FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@er_pin}'"
                    b1 = Database.my_select_last_statement a
                    b1.should nil # PIN IN TXN_OCCUPANCY_LIST TABLE
            Database.logoff
            slmc.login(@user, @password).should be_true
            slmc.admission_search(:pin => @@er_pin)
            slmc.acknowledge_inpatient(:pin => @@er_pin).should be_true
            Database.connect
                      a = "SELECT VISIT_NO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@er_pin}'"
                      b = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@er_pin}'"
                      c = "SELECT VISIT_NO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@er_pin}')"
                      d = "SELECT ROOMNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@er_pin}'"
                      e = "SELECT ROOMNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@er_pin}')"
                      f = "SELECT BEDNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@er_pin}'"
                      g = "SELECT BEDNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@er_pin}')"
                      h = "SELECT NURSING_UNIT  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@er_pin}'"
                      i = "SELECT NURSING_UNIT FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@er_pin}')"
                      j = "SELECT CONFIDENTIAL FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@er_pin}'"
                      k = "SELECT CONFIDENTIAL FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@er_pin}'"
                      l  = "SELECT REDTAG_FLAG, DEATH_TYPE, DEATH_FLAG, ENDORSEMENT_FLAG, ROOMTRAN_RQST_STATUS, PACKAGE_RATE_NO, DIET_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@er_pin}'"

                      a1 = Database.my_select_last_statement a
                      b1 = Database.my_select_last_statement b
                      c1 = Database.my_select_last_statement c
                      d1 = Database.my_select_last_statement d
                      e1 = Database.my_select_last_statement e
                      f1 = Database.my_select_last_statement f
                      g1 = Database.my_select_last_statement g
                      h1 = Database.my_select_last_statement h
                      i1 = Database.my_select_last_statement i
                      j1 = Database.my_select_last_statement j
                      k1 = Database.my_select_last_statement k
                      l1 = Database.select_all_statement l


                      a1.should_not  nil  #VISIT NUMBER IN OCCUPANCY LIST TABLE
                      a1.should  == c1   #VISIT NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      b1.should_not  nil # PIN IN ADM ENCOUTER TABLE
                      d1.should  == e1 #ROOM NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      f1.should  == g1  #BEDNUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      h1.should  == i1  #NURSING_UNIT IN OCCUPANCY LIST AND ADM IN TABLE
                      j1.should  == k1  #CONFIDENTIAL IN OCCUPANCY LIST AND ADM IN TABLE
                      l1[0].should == 'N'
                      l1[1].should == nil
                      l1[2].should == 'N'
                      l1[3].should == 'N'
                      l1[4].should == '-'
                      l1[5].should == nil
                      l1[6].should == "Y"
                      l1[7].should == 'A'
            Database.logoff

end
  it "6338 - Cancellation of Patients adm" do
            @patient1 = Admission.generate_data
            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
            puts @@pin1
 #            @@pin1 = "1410076100"
            Database.connect
                      a = "SELECT VISIT_NO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      b = "SELECT PIN FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}'"
                      c = "SELECT VISIT_NO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                      d = "SELECT ROOMNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      e = "SELECT ROOMNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                      f = "SELECT BEDNO  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      g = "SELECT BEDNO FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                      h = "SELECT NURSING_UNIT  FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      i = "SELECT NURSING_UNIT FROM SLMC.TXN_ADM_IN WHERE VISIT_NO = (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}')"
                      j = "SELECT CONFIDENTIAL FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                      k = "SELECT CONFIDENTIAL FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin1}'"
                      l  = "SELECT REDTAG_FLAG, DEATH_TYPE, DEATH_FLAG, ENDORSEMENT_FLAG, ROOMTRAN_RQST_STATUS, PACKAGE_RATE_NO, DIET_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"



                      a1 = Database.my_select_last_statement a
                      b1 = Database.my_select_last_statement b
                      c1 = Database.my_select_last_statement c
                      d1 = Database.my_select_last_statement d
                      e1 = Database.my_select_last_statement e
                      f1 = Database.my_select_last_statement f
                      g1 = Database.my_select_last_statement g
                      h1 = Database.my_select_last_statement h
                      i1 = Database.my_select_last_statement i
                      j1 = Database.my_select_last_statement j
                      k1 = Database.my_select_last_statement k
                      l1 = Database.select_all_statement l


                      a1.should_not  nil  #VISIT NUMBER IN OCCUPANCY LIST TABLE
                      a1.should  == c1   #VISIT NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      b1.should_not  nil # PIN IN ADM ENCOUTER TABLE
                      d1.should  == e1 #ROOM NUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      f1.should  == g1  #BEDNUMBER IN OCCUPANCY LIST AND ADM IN TABLE
                      h1.should  == i1  #NURSING_UNIT IN OCCUPANCY LIST AND ADM IN TABLE
                      j1.should  == k1  #CONFIDENTIAL IN OCCUPANCY LIST AND ADM IN TABLE
                      l1[0].should == 'N'
                      l1[1].should == nil
                      l1[2].should == 'N'
                      l1[3].should == 'N'
                      l1[4].should == '-'
                      l1[5].should == nil
                      l1[6].should == "Y"
                      l1[7].should == 'A'
            Database.logoff
#            @@pin1 = "1410076351"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.click "link=Cancel Admission"
            sleep 3
            slmc.type "name=reason", "Selenium Test"
            sleep 3
            slmc.click("//html/body/div[12]/div[3]/div/button")
            sleep 6
            slmc.is_text_present("Patient admission details successfully cancelled.").should be_true
            Database.connect
                        a = "SELECT * FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                        b1 = Database.my_select_last_statement a
                        b1.should nil # PIN IN TXN_OCCUPANCY_LIST TABLE
            Database.logoff
end
  it "6338 - Patients for Room transfer" do
            @patient1 = Admission.generate_data
            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "-"
            puts @@pin1
            slmc.login(@gu_user_0287, @password)
            slmc.go_to_general_units_page
            sleep 3
            slmc.go_to_gu_room_tranfer_page(:pin => @@pin1)
            sleep 3
            slmc.type "id=txtRemarks", "asdas"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "RQS01"
            slmc.login(@user, @password)
            slmc.go_to_admission_page
            sleep 3
            slmc.click "id=roomTransferImg"
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Update Request Status"
            sleep 3
            slmc.click "css=option[value=\"update\"]"
            sleep 3
            slmc.select "id=optRequestStatus", "label=With Feedback"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "RQS02"


            slmc.login(@gu_user_0287, @password)
            slmc.go_to_general_units_page
            sleep 3
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Update Request Status"
            sleep 3
            slmc.select "id=optRequestStatus", "label=With Feedback"
            sleep 3
            slmc.type "id=txtRemarks", "SELENIUM TEST"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "RQS02"

            slmc.login(@user, @password)
            slmc.go_to_admission_page
            sleep 3
            slmc.click "id=roomTransferImg"
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Update Request Status"
            sleep 3
            slmc.click "css=option[value=\"update\"]"
            sleep 3
            slmc.select "id=optRequestStatus", "label=For Room Transfer"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "RQS05"

            slmc.login(@gu_user_0287, @password)
            slmc.go_to_general_units_page
            sleep 3
            slmc.click "id=roomTransferImg"
            sleep 3
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Update Request Status"
            sleep 3
            slmc.select "id=optRequestStatus", "label=Physically Transferred"
            sleep 3
            slmc.type "id=txtRemarks", "SELENIUM TEST"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "RQS03"


            slmc.login(@user, @password)
            slmc.go_to_admission_page
            slmc.click "id=roomTransferImg"
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Transfer Room Location"
            sleep 3
            sam = slmc.transfer_room_location(:room_charge => "REGULAR PRIVATE", :transfer_type => "BED TRANSFER", :room => true, :nursing_unit => "0287")
            puts sam
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "RQS04"

          @patient1 = Admission.generate_data
            slmc.login(@user, @password)
            slmc.admission_search(:pin => "Test")
            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
            #@@pin1 = "1210068782"
            slmc.login(@user, @password)
            slmc.admission_search(:pin => @@pin1).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "-"

            slmc.login(@gu_user_0287, @password)
            slmc.go_to_general_units_page
            sleep 3
            slmc.go_to_gu_room_tranfer_page(:pin => @@pin1)
            sleep 3
            slmc.type "id=txtRemarks", "asdas"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "RQS01"

            slmc.go_to_general_units_page
            sleep 3
            slmc.click "id=roomTransferImg"
            sleep 3
            slmc.type "id=pendingRtrPatientSearchKey", @@pin1
            sleep 3
            slmc.click "id=btnPendingRtrSearch"
            sleep 3
            slmc.select "css=select", "label=Update Request Status"
            sleep 3
            slmc.select "id=optRequestStatus", "label=Cancelled"
            sleep 3
            slmc.type "id=txtRemarks", "SELENIUM TEST"
            sleep 3
            slmc.click("id=btnRtrOk", :wait_for => :page)
            Database.connect
                           l  = "SELECT ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                          e1 = Database.select_last_statement l
            Database.logoff
            e1.should == "RQS06"

end
  it "6338 - Patients with Endorsement" do
                @patient1 = Admission.generate_data
                slmc.login("adm1", @password)
                slmc.admission_search(:pin => "Test")
                @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
                #@@pin1 = "1210068782"
                slmc.login("adm1", @password)
                slmc.admission_search(:pin => @@pin1).should be_true
                slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
                :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."

                puts @@pin1
                slmc.login(@gu_user_0287, @password)
                slmc.go_to_general_units_page
                don_endorsement_count = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/span")
                don_endorsement_count = (don_endorsement_count).to_i
                puts "Initail count in nursing= #{don_endorsement_count}"
#10
                slmc.login("adm1", @password)
                slmc.admission_search(:pin => @@pin1)
                slmc.click("link=Endorsement Tagging",:wait_for => :page)
                slmc.click "name=btnAddNew"
                slmc.select "id=add_endorsementType", "label=SPECIAL ARRANGEMENTS"
                slmc.click "css=#add_endorsementType > option[value=\"END6\"]"
                slmc.select "id=add_endorsementType", "label=UNSETTLED ACCOUNTS"
                #page.click "css=#add_endorsementType > option[value=\"END8\"]"
                slmc.type "id=endorsement_textarea", "selenuim test"
                sleep 3
                slmc.add_selection"id=destination_select", "label=DIVISION OF NURSING"
                slmc.click("name=btnSave", :wait_for => :page)
                Database.connect
                             l  = "SELECT ENDORSEMENT_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                            l1 = Database.select_all_statement l
                Database.logoff
                 l1[0].should == "Y"
                 l1[1].should == "A"

                  slmc.login(@gu_user_0287, @password)
                  slmc.go_to_general_units_page
                  don_endorsement_count_after_saved = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/span")
                  don_endorsement_count_after_saved = (don_endorsement_count_after_saved).to_i
                  don_endorsement_count_after_saved.should == don_endorsement_count + 1
                  puts " Count  in nursing  after adding in adm = #{don_endorsement_count_after_saved}"
  #11
                  slmc.go_to_general_units_page
                  don_endorsement_count = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/span")
                  don_endorsement_count = (don_endorsement_count).to_i
                  puts " re- count  in nursing  after adding in adm = #{don_endorsement_count}"
  #11
                  slmc.nursing_gu_search(:pin => @@pin1)
                  slmc.go_to_gu_page_for_a_given_pin("Endorsement Tagging", @@pin1)
                  slmc.is_text_present("Patient Endorsement List").should be_true
                  slmc.click("css=img[alt=\"Delete\"]", :wait_for =>:page)
                  slmc.is_text_present("No endorsement saved.").should be_true
                  slmc.go_to_general_units_page
                  don_endorsement_count_after_delete = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/span")
                  don_endorsement_count_after_delete = (don_endorsement_count_after_delete).to_i
                  don_endorsement_count_after_delete.should == don_endorsement_count -1
                  puts " Count  in nursing  after adding in adm = #{don_endorsement_count_after_delete}"
  #10
                  Database.connect
                               l  = "SELECT ENDORSEMENT_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                              l1 = Database.select_all_statement l
                  Database.logoff
                  l1[0].should == "N"
                  l1[1].should == "A"

                  slmc.nursing_gu_search(:pin => @@pin1)
                  slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin1)
                  @ancillary3.each do |item, q|
                          slmc.search_order(:description => item, :ancillary => true).should be_true
                          slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
                  end
                  sleep 2
                  slmc.submit_added_order.should be_true
                  slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
                  slmc.confirm_validation_all_items.should be_true
                  slmc.nursing_gu_search(:pin=> @@pin1)
                  @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin1, :pf_type => "COLLECT", :pf_amount => '1000', :no_pending_order => true, :save => true)


                  slmc.login(@pba_user, @password)
                  slmc.go_to_patient_billing_accounting_page
                  slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
                  slmc.go_to_page_using_visit_number("Endorsement Tagging", slmc.visit_number)
                  slmc.endorsement_tagging(:endorsement_type => "TAKE HOME MEDICINES", :don => true, :add => true, :save => true).should be_true
                  Database.connect
                               l  = "SELECT ENDORSEMENT_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                              l1 = Database.select_all_statement l
                  Database.logoff
                  l1[0].should == "Y"
                  l1[1].should == "C"

                  slmc.login(@gu_user_0287, @password)
                  slmc.go_to_general_units_page
                  don_endorsement_count_after_add = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/span")
                  don_endorsement_count_after_add = (don_endorsement_count_after_add).to_i
                  don_endorsement_count_after_add.should == don_endorsement_count_after_delete + 1
                  puts " Count  in nursing  after adding in billing = #{don_endorsement_count_after_add}"
  #11

                  slmc.login(@pba_user, @password)
                  slmc.go_to_patient_billing_accounting_page
                  slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
                  slmc.go_to_page_using_visit_number("Endorsement Tagging", slmc.visit_number)
                  slmc.click "css=img[alt=\"Delete\"]", :wait_for => :page
                  slmc.is_text_present("No endorsement saved.").should be_true

                  slmc.login(@gu_user_0287, @password)
                  slmc.go_to_general_units_page
                  don_endorsement_count_after_del = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/span")
                  don_endorsement_count_after_del = (don_endorsement_count_after_del).to_i
                  don_endorsement_count_after_del.should == don_endorsement_count_after_add - 1
  #10
                  puts " Count  in nursing  after delete  in billing = #{don_endorsement_count_after_del}"
                  Database.connect
                               l  = "SELECT ENDORSEMENT_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                l1 = Database.select_all_statement l
                  Database.logoff
                  l1[0].should == "N"
                  l1[1].should == "C"


                slmc.login(@inhouse_user, @password).should be_true
                slmc.inhouse_search(:pin => @@pin1)
                slmc.go_to_inhouse_page("Endorsement Tagging", @@pin1)
                slmc.endorsement_tagging(:endorsement_type => "SPECIAL ARRANGEMENTS", :don => true, :add => true, :save => true).should be_true

                  Database.connect
                               l  = "SELECT ENDORSEMENT_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                l1 = Database.select_all_statement l
                  Database.logoff
                  l1[0].should == "Y"
                  l1[1].should == "C"

                  slmc.login(@gu_user_0287, @password)
                  slmc.go_to_general_units_page
                  don_endorsement_count_after_add_inhouse= slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/span")
                  don_endorsement_count_after_add_inhouse = (don_endorsement_count_after_add_inhouse).to_i
                  don_endorsement_count_after_add_inhouse.should == don_endorsement_count_after_del + 1
  #11


                slmc.login(@inhouse_user, @password).should be_true
                slmc.inhouse_search(:pin => @@pin1)
                slmc.go_to_inhouse_page("Endorsement Tagging", @@pin1)
                slmc.endorsement_tagging(:delete => true).should be_true

                  slmc.login(@gu_user_0287, @password)
                  slmc.go_to_general_units_page
                  don_endorsement_count_after_del_inhouse = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/span")
                  don_endorsement_count_after_del_inhouse = (don_endorsement_count_after_del_inhouse).to_i
                  don_endorsement_count_after_del_inhouse.should == don_endorsement_count_after_add_inhouse - 1
  #11


end
  it "6338 - Patients without Encoded Diet" do
                @patient1 = Admission.generate_data
                slmc.login("adm1", @password)
                slmc.admission_search(:pin => "Test")
                @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
                #@@pin1 = "1210068782"
                slmc.login("adm1", @password)
                slmc.admission_search(:pin => @@pin1).should be_true
                slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
                :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."

                Database.connect
                               l  = "SELECT DIET_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                l1 = Database.select_all_statement l
                Database.logoff
                l1[0].should == "Y"
                l1[1].should == "A"

                slmc.login(@gu_user_0287, @password)
                slmc.go_to_general_units_page
                slmc.nursing_gu_search(:pin => @@pin1)
                slmc.go_to_gu_page_for_a_given_pin("Clinical Diet", @@pin1)
                slmc.add_clinical_diet(:save => true, :nutritionally_at_risk =>"NO").should == "Patient diet COMPUTED DIET successfully created."
                Database.connect
                               l  = "SELECT DIET_FLAG, STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
                                l1 = Database.select_all_statement l
                Database.logoff
                l1[0].should == "N"
                l1[1].should == "A"
  end 
end