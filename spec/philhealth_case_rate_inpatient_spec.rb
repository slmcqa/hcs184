require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'ruby-plsql'


describe "Philhealth_Case_rate_Inpatient" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver


  before(:all) do
     @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    #username
    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
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


  it "EXEMPTED SPC RULE - CATARACT SURGERY - Create, Admit and Order items" do
    @patient1 = Admission.generate_data
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
  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Get Gross Order " do
    @@comp_drugs = 0
    @@comp_xray_lab = 0
    @@comp_operation = 0
    @@comp_others = 0
    @@comp_supplies = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@non_comp_xray_lab = 0
    @@non_comp_operation = 0
    @@non_comp_others = 0
    @@non_comp_supplies = 0

    @@orders = @drugs1.merge(@ancillary1).merge(@supplies1)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS04"
        other_amt = item[:rate].to_f * n
        @@comp_others += other_amt  # total compensable others
      end
      if item[:ph_code] == "PHS05"
        supp_amt = item[:rate].to_f * n
        @@comp_supplies += supp_amt  # total compensable supplies
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
        n_amt_tag = item[:rate].to_f * n
        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
      end
      if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
      end
      if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
      end
      if item[:ph_code] == "PHS09"
        n_other_amt = item[:rate].to_f * n
        @@non_comp_others += n_other_amt  # total non compensable others
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Compute Philhealth" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "66983", :compute => true)
    slmc.ph_save_computation.should be_true

  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Verify Case Rate And PF Fee" do
     @@mycase_rate =  "66983"
     Database.connect
            t = "SELECT TO_CHAR(PF_AMOUNT) FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
            pf = Database.select_last_statement t
     Database.logoff
     Database.connect
            t = "SELECT TO_CHAR(RATE)  FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
            rate = Database.select_last_statement t
     Database.logoff
     mm = @@ph1[:total_actual_benefit_claim].to_f
     puts mm
     puts rate
     puts pf
     pf = pf.to_i
     rate = rate.to_i
#
#     @@comp_drugs
#     @@comp_xray_lab
#     @@comp_operation
#     @@comp_others
#     @@comp_supplies
#     @@non_comp_drugs
#     @@non_comp_drugs_mrp_tag
#     @@non_comp_xray_lab
#     @@non_comp_operation
#     @@non_comp_others
#     @@non_comp_supplies

     @@total_actual_benefit_claim = (rate - pf )#REF_PBA_PH_CASE_RATE.CASE_RATE_NO = '5381'
     @@physician_pf_claim = pf
     puts "@@total_actual_benefit_claim - #{@@total_actual_benefit_claim}"
     puts "@@ph1[:total_actual_benefit_claim #{mm}"
     ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
     ((slmc.truncate_to((@@ph1[:inpatient_physician_benefit_claim].to_f - @@physician_pf_claim),2).to_f).abs).should <= 0.01
  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Checks if the actual charge for drugs/medicine is correct" do
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Checks if the actual charge for room and board is correct" do
    @@days1 = 1.0
    @@actual_room_charges = (@@room_discount * @@days1)
    @@ph1[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Checks if the total actual charge(s) is correct" do
    @@total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph1[:total_actual_charges].to_f - @@total_actual_charges),2).to_f).abs).should <= 0.01
  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - Settle Balance Due" do
    sleep 10
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
   @@summary = slmc.get_billing_details_from_payment_data_entry
    puts @@summary[:hospital_bill]
    puts @@summary[:room_charges]
    puts @@summary[:adjustments]
    puts @@summary[:philhealth]
    puts @@summary[:discounts]
    puts @@summary[:ewt]
    puts @@summary[:gift_check]
    puts @@summary[:payments]
    puts @@summary[:charged_amount]
    puts @@summary[:social_service_coverage]
    puts @@summary[:total_hospital_bills]
    puts @@summary[:pf_amount]
    puts @@summary[:pf_payments]
    puts @@summary[:pf_charged]
    puts @@summary[:total_amount_due]
    puts @@summary[:total_payments]
    puts @@summary[:balance_due]

#    (@@discount_amount + @@total_actual_charges)

    payment =  (@@total_actual_charges - (@@total_actual_benefit_claim ))
    #payment = payment.round.to_f
    payment =  ('%.2f' %  + payment.to_f)
    slmc.my_pba_full_payment(:cash => payment, :pf_amount => @@physician_pf_claim).should be_true

      #Verify PF
      #Click Skip philhealth
      #click skip dicount
      #Verify payment page

  end
  it "EXEMPTED SPC RULE - CATARACT SURGERY  - Print Gatepass" do
       ######## Print Gate Pass
       slmc.login(@gu_user_0287, @password).should be_true
       slmc.nursing_gu_search(:pin => @@pin1)
       slmc.print_gatepass(:no_result => true, :pin => @@pin1).should be_true



  end
  it "EXEMPTED SPC RULE - NOT CATARACT SURGERY  - Create, Admit and Order items  And Verify Total PH Claims" do
#    @patient1 = Admission.generate_data
#    slmc.login(@user, @password)
#    slmc.admission_search(:pin => "Test")
#    @@pin2 = slmc.create_new_patient(@patient1).gsub(' ', '')
#  #  @@pin1 = "1210068782"
#    slmc.admission_search(:pin => @@pin2).should be_true
#    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
#      :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
#
#    slmc.login(@gu_user_0287, @password)
#    slmc.go_to_general_units_page
#    slmc.go_to_adm_order_page(:pin => @@pin2)
#    @drugs1.each do |item, q|
#                  slmc.search_order(:description => item, :drugs => true).should be_true
#                  slmc.add_returned_order(:drugs => true, :description => item,:quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
#    end
#    @ancillary1.each do |item, q|
#                  slmc.search_order(:description => item, :ancillary => true).should be_true
#                  slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
#    end
#    @supplies1.each do |item, q|
#                  slmc.search_order(:description => item, :supplies => true).should be_true
#                  slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#    slmc.confirm_validation_all_items.should be_true
#
#    slmc.go_to_general_units_page
#    slmc.nursing_gu_search(:pin => @@pin2)
#    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
#    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@pin2, :diagnosis => "A91.0", :no_pending_order => true, :pf_amount => "3000", :save => true).should be_true
#    puts @@pin2
#
#    slmc.login(@pba_user, @password)
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
#    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
#    slmc.skip_update_patient_information.should be_true
#    slmc.skip_room_and_bed_cancelation.should be_true
#    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "66983", :compute => true)
#    slmc.ph_save_computation.should be_true
#    @@mycase_rate =  "11720"
#     Database.connect
#            t = "SELECT PF_AMOUNT FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
#            pf = Database.select_last_statement t
#     Database.logoff
#     Database.connect
#            t = "SELECT RATE  FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
#            rate = Database.select_last_statement t
#     Database.logoff
#      puts rate
#
#      puts pf
#      pf = pf.to_i
#      rate = rate.to_i
#      @@total_actual_benefit_claim = (rate - pf )#REF_PBA_PH_CASE_RATE.CASE_RATE_NO = '5381'
#      mm = @@ph1[:total_actual_benefit_claim].to_i
#      puts mm
#      ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
#      #Verify PF
#      #Click Skip philhealth
#      #click skip dicount
#      #Verify payment page




    end


  it "EXEMPTED SPC RULE - CATARACT SURGERY - MORE THAN 1 DAY AND LESS THAN 2 DAY - Create, Admit and Order items  And Verify Total PH Claims" do
            days_to_adjust = 1
            d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
            #my_set_date = ((d - days_to_adjust).strftime("%d/%m/%Y").upcase).to_s
            my_set_date = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s
            Database.connect
                   #@@visit_no1 = "5409000018"
                  visit_no = @@visit_no1
                   plsql.connection = Database.connect
                              a = plsql.slmc.sproc_updater(visit_no,my_set_date,my_set_date)
                   plsql.logoff
            Database.logoff
            puts a
    #        @@pin1 = "1409074339"
            slmc.login(@gu_user_0287, @password)
            slmc.nursing_gu_search(:pin => @@pin1)
            slmc.print_gatepass(:no_result => true, :pin => @@pin1)
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
            @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@pin1, :diagnosis => "A91.0", :no_pending_order => true, :pf_amount => "3000", :save => true).should be_true
            puts @@pin1

#            slmc.login(@pba_user, @password)
#            slmc.go_to_patient_billing_accounting_page
#            slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
#            slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#            slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
#            slmc.skip_update_patient_information.should be_true
#            slmc.skip_room_and_bed_cancelation.should be_true
#            @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "66983", :compute => true)
#            slmc.ph_save_computation.should be_true
#            @@mycase_rate =  "66983"
#            Database.connect
#                    t = "SELECT PF_AMOUNT FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
#                    pf = Database.select_last_statement t
#            Database.logoff
#            Database.connect
#                    t = "SELECT RATE  FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
#                    rate = Database.select_last_statement t
#            Database.logoff
#            puts rate
#
#            puts pf
#            pf = pf.to_i
#            rate = rate.to_i
#            @@total_actual_benefit_claim = (rate - pf )#REF_PBA_PH_CASE_RATE.CASE_RATE_NO = '5381'
#            mm = @@ph1[:total_actual_benefit_claim].to_i
#            puts mm
#            ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
#            #Verify PF
#            #Click Skip philhealth
#            #click skip dicount
#            #Verify payment page

end
  it "EXEMPTED SPC RULE - CATARACT SURGERY - MORE THAN 2 DAY - Create, Admit and Order items  And Verify Total PH Claims" do
#            days_to_adjust = 3
#            d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
#            #my_set_date = ((d - days_to_adjust).strftime("%d/%m/%Y").upcase).to_s
#            my_set_date = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s
#            Database.connect
#                   @@visit_no1 = "5409000018"
#                  visit_no = @@visit_no1
#                   plsql.connection = Database.connect
#                              a = plsql.slmc.sproc_updater(visit_no,my_set_date,my_set_date)
#                   plsql.logoff
#            Database.logoff
#            puts a
#            @@pin1 = "1409074339"
#
#
#            slmc.login(@pba_user, @password)
#            slmc.go_to_patient_billing_accounting_page
#            slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
#            slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#            slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
#            slmc.skip_update_patient_information.should be_true
#            slmc.skip_room_and_bed_cancelation.should be_true
#            @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "66983", :compute => true)
#            slmc.ph_save_computation.should be_true
#            @@mycase_rate =  "66983"
#            Database.connect
#                    t = "SELECT PF_AMOUNT FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
#                    pf = Database.select_last_statement t
#            Database.logoff
#            Database.connect
#                    t = "SELECT RATE  FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
#                    rate = Database.select_last_statement t
#            Database.logoff
#            puts rate
#
#            puts pf
#            pf = pf.to_i
#            rate = rate.to_i
#            @@total_actual_benefit_claim = (rate - pf )#REF_PBA_PH_CASE_RATE.CASE_RATE_NO = '5381'
#            mm = @@ph1[:total_actual_benefit_claim].to_i
#            puts mm
#            ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
#            #Verify PF
#            #Click Skip philhealth
#            #click skip dicount
#            #Verify payment page


end
end




