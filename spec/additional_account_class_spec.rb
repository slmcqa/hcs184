require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

#USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Patient Billing and Accounting - Additional Account Class Discount (Women's Board)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver
sad
  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @inpatient = Admission.generate_data
    @password = "123qweuser"
    @gu_spec_user =  "gycapalungan" #"gu_spec_user10"
            #@pba_user = "ldcastro" #"sel_pba7"
            @pba_user = "pba1" #"sel_pba7"
    @oss_user = "jtsalang" #"sel_oss8"
    @or_user = "slaquino" #"sel_or8"
    @dr_user = "jpnabong" #"sel_dr2"
    @er_user = "jtabesamis" #"sel_er6"
  @user = "ldvoropesa"  #admission_login#
    @ancillary = {"010001194" => 1, "010001448" => 1}
    @promo_discount   = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@inpatient[:age])
    @promo_discount_senior = 0.2
    @promo_discount_non_senior = 0.16
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
  
  it"Women's Board Member - Inpatient, Creates Patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin = slmc.create_new_patient(@inpatient.merge(:gender => 'F')).gsub(' ', '')
      # slmc.login(@gu_spec_user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin)#.should be_true
    slmc.create_new_admission(:account_class => "WOMEN'S BOARD MEMBER", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :guarantor_code => "WOMB001").should == "Patient admission details successfully saved."
  end
  it"Women's Board Member - Inpatient, Order Items" do
    slmc.login(@gu_spec_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@inpatient_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Women's Board Member - Inpatient, Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @@inpatient_pin)
    @@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@inpatient_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
  it"Women's Board Member - Inpatient, PBA Standard Discharge Patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
  it"Women's Board Member - Inpatient, Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "WOMB001"
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it"Women's Board Member - Inpatient, Check Discount Details" do# not included on test case. checking if wbm discount is applied
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f

    @original_discount_promo = @total_charges*@promo_discount
    @discount_promo = @total_charges - @original_discount_promo
    @discount_class = (@discount_promo * 20).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo+@discount_class)).to_f
    @@summary[:total_hospital_bills].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - Inpatient, Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
  it"Women's Board Member - OSS, Creates Patient" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(Admission.generate_data(:not_senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
  end
  it"Women's Board Member - OSS, Add Guarantor" do
        slmc.login(@oss_user, @password).should be_true
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type => "WOMEN'S BOARD", :acct_class => "WOMEN'S BOARD MEMBER", :guarantor_code => "WOMB001", :guarantor_add => true)
  end
  it"Women's Board Member - OSS, Order Items" do
     @ancillary.each do |item, q|
     slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
     end
  end
  it"Women's Board Member - OSS, Check Discount Information Details" do
    slmc.click "orderToggle"
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f  * @promo_discount_non_senior
    @discount_promo = @@summary[:total_gross_amount].to_f - @original_discount_promo
    @discount_class =  (@discount_promo * 20).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:total_class_discount].to_f.should == ("%0.2f" %(@discount_class)).to_f
    @@summary[:total_net_amount].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - OSS, Discharge to Payment" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end
  it"Women's Board Member - OR, Creates Patient" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(Admission.generate_data(:senior => true).merge!(
    :admit => true, :gender => 'F', :account_class => "WOMEN'S BOARD MEMBER", :org_code => "0164",
    :guarantor_type => "WOMEN'S BOARD", :guarantor_code => "WOMB001")).gsub(' ', '').should be_true
  end
  it"Women's Board Member - OR, Order Items" do
        slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    puts @@or_pin
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Women's Board Member - OR, Clnically Discharge Patient" do
    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:pin => @@or_pin, :outpatient => true, :pf_amount => "1000", :save => true, :no_pending_order => true).should be_true
   # @@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@or_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
  it"Women's Board Member - OR, PBA Standard Discharge Patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
  it"Women's Board Member - OR, Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "WOMB001"
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it"Women's Board Member - OR, Check Discount Information Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f  * @promo_discount_senior
    @discount_promo = @@summary[:hospital_bill].to_f  - @original_discount_promo
    @discount_class = (@discount_promo * 20).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo+@discount_class)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - OR, Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
  it"Women's Board Member - DR, Creates Patient" do
    slmc.login(@dr_user,@password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration
    @@dr_pin = slmc.outpatient_registration(Admission.generate_data(:senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
        slmc.login(@dr_user,@password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.click_register_patient
    slmc.admit_er_patient(:org_code => "0170", :account_class =>  "WOMEN'S BOARD MEMBER", :guarantor => true, :guarantor_type => "WOMEN'S BOARD", :guarantor_code => "WOMB001").should be_true
  end
  it"Women's Board Member - DR, Order Items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Women's Board Member - DR, Clnically Discharge Patient" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Discharge Instructions\302\240", @@dr_pin)
    slmc.add_final_diagnosis(:save => true)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Doctor and PF Amount", @@dr_pin)
    slmc.clinical_discharge(:no_pending_order => true, :pf_amount => "1000").should be_true
  end
  it"Women's Board Member - DR, PBA Standard Discharge Patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
  it"Women's Board Member - DR, Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "WOMB001"
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it"Women's Board Member - DR, Check Discount Information Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f  * @promo_discount_senior
    @discount_promo = @@summary[:hospital_bill].to_f - @original_discount_promo
    @discount_class = (@discount_promo * 20).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo+@discount_class)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - DR, Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
  it"Women's Board Member - ER, Creates Patient" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    @@er_pin = slmc.ss_create_outpatient_er(Admission.generate_data(:senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
        slmc.go_to_er_page
        slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_landing_page
    slmc.er_patient_search(:pin => @@er_pin)
    slmc.click_register_patient
    slmc.admit_er_patient(:org_code => "0173", :account_class =>  "WOMEN'S BOARD MEMBER").should be_true
  end
  it"Women's Board Member - ER, Order Items" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Women's Board Member - ER, Clnically Discharge Patient" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
  it"Women's Board Member - ER, Add Guarantor" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin)
    slmc.go_to_pba_action_page(:visit_no => @@visit_no, :page => "Update Patient Information" )
    slmc.click_new_guarantor
    slmc.pba_update_guarantor(:guarantor_type => "WOMEN'S BOARD", :guarantor_code => "WOMB001").should be_true
    slmc.click_submit_changes.should be_true
  end
  it"Women's Board Member - ER, Standard Discharge Patient" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin)
    slmc.go_to_pba_action_page(:visit_no => @@visit_no, :page => "Discharge Patient" )
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
  it"Women's Board Member - ER, Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "WOMB001"
    slmc.skip_update_patient_information.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it"Women's Board Member - ER, Check Discount Information Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f  * @promo_discount_senior
    @discount_promo = @@summary[:hospital_bill].to_f  - @original_discount_promo
    @discount_class = (@discount_promo * 20).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo+@discount_class)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - ER, Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
  it"Women's Board Member - Dependent - Inpatient, Creates Patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin1 = slmc.create_new_patient(Admission.generate_data(:not_senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin1)
    slmc.create_new_admission(:account_class => "WOMEN'S BOARD DEPENDENT", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :guarantor_code => "WOMB001").should == "Patient admission details successfully saved."
  end
  it"Women's Board Member - Dependent - Inpatient, Order Items" do
    slmc.login(@gu_spec_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@inpatient_pin1)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin1)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Women's Board Member - Dependent - Inpatient, Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @@inpatient_pin1)
    @@inpatient_visit_no1 = slmc.clinically_discharge_patient(:pin => @@inpatient_pin1, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
  it"Women's Board Member - Dependent - Inpatient, PBA Standard Discharge Patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
  it"Women's Board Member - Dependent - Inpatient, Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "WOMB001"
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it"Women's Board Member - Dependent - Inpatient, Check Discount Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f

    @original_discount_promo = @total_charges*@promo_discount_non_senior
    @discount_promo = @total_charges - @original_discount_promo
    @discount_class = (@discount_promo * 10).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo+@discount_class)).to_f
    @@summary[:total_hospital_bills].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - Dependent - Inpatient, Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
  it"Women's Board Member - Dependent - OSS, Creates Patient" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin1 = slmc.oss_outpatient_registration(Admission.generate_data(:senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
  end
  it"Women's Board Member - Dependent - OSS, Add Guarantor" do
        slmc.login(@oss_user, @password).should be_true
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin1)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type =>  "WOMEN'S BOARD", :acct_class =>  "WOMEN'S BOARD DEPENDENT", :guarantor_code => "WOMB001", :guarantor_add => true)
     slmc.type"seniorIdNumber","123456789"
  end
  it"Women's Board Member - Dependent - OSS, Order Items" do
     @ancillary.each do |item, q|
     slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
     end
  end
  it"Women's Board Member - Dependent - OSS, Check Discount Information Details" do
    slmc.click "orderToggle"
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f  * @promo_discount_senior
    @discount_promo = @@summary[:total_gross_amount].to_f - @original_discount_promo
    @discount_class =  (@discount_promo * 10).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:total_class_discount].to_f.should == ("%0.2f" %(@discount_class)).to_f
    @@summary[:total_net_amount].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - Dependent - OSS, Discharge to Payment" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end
  it"Women's Board Member - Dependent - OR, Creates Patient" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin1 = slmc.or_create_patient_record(Admission.generate_data(:senior => true).merge!(
    :admit => true, :gender => 'F', :account_class => "WOMEN'S BOARD DEPENDENT", :org_code => "0164",
    :guarantor_type => "WOMEN'S BOARD", :guarantor_code => "WOMB001")).gsub(' ', '').should be_true
  end
  it"Women's Board Member - Dependent - OR, Order Items" do
        slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin1)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin1)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Women's Board Member - Dependent - OR, Clnically Discharge Patient" do
    slmc.login("or1", @password).should be_true
    slmc.go_to_occupancy_list_page
    sleep 5
   slmc.clinically_discharge_patient(:pin => @@or_pin1, :outpatient => true, :pf_amount => "1000", :save => true, :no_pending_order => true).should be_true
   #    slmc.clinically_discharge_patient(:pin => @@or_pin1, :or => true, :pf_amount => "1000", :save => true, :no_pending_order => true).should be_true
    #@@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@or_pin1, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
  it"Women's Board Member - Dependent - OR, PBA Standard Discharge Patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
  it"Women's Board Member - Dependent - OR, Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "WOMB001"
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it"Women's Board Member - Dependent - OR, Check Discount Information Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f  * @promo_discount_senior
    puts "promo or senoir : #{@promo_discount_senior}"
    puts "orginaldiscount : #{@original_discount_promo}"
    @discount_promo = @@summary[:hospital_bill].to_f - @original_discount_promo

    @discount_class = (@discount_promo * 10).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo+@discount_class)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - Dependent - OR, Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
  it"Women's Board Member - Dependent - DR, Creates Patient" do
    slmc.login(@dr_user,@password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration
    @@dr_pin1 = slmc.outpatient_registration(Admission.generate_data(:senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
        slmc.login(@dr_user,@password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@dr_pin1)
    slmc.click_register_patient
    slmc.admit_er_patient(:org_code => "0170", :account_class =>  "WOMEN'S BOARD DEPENDENT", :guarantor => true, :guarantor_type => "WOMEN'S BOARD", :guarantor_code => "WOMB001").should be_true
  end
  it"Women's Board Member - Dependent - DR, Order Items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin1)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Women's Board Member - Dependent - DR, Clnically Discharge Patient" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1).should be_true
    slmc.go_to_su_page_for_a_given_pin("Discharge Instructions\302\240", @@dr_pin1)
    slmc.add_final_diagnosis(:save => true)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1).should be_true
    slmc.go_to_su_page_for_a_given_pin("Doctor and PF Amount", @@dr_pin1)
    slmc.clinical_discharge(:no_pending_order => true, :pf_amount => "1000").should be_true
  end
  it"Women's Board Member - Dependent - DR, PBA Standard Discharge Patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
  it"Women's Board Member - Dependent - DR, Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "WOMB001"
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it"Women's Board Member - Dependent - DR, Check Discount Information Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f  * @promo_discount_senior
    @discount_promo = @@summary[:hospital_bill].to_f - @original_discount_promo
    @discount_class = (@discount_promo * 10).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo+@discount_class)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - Dependent - DR, Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
  it"Women's Board Member - Dependent - ER, Creates Patient" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    @@er_pin1 = slmc.ss_create_outpatient_er(Admission.generate_data(:not_senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
        slmc.login(@er_user, @password).should be_true
            slmc.go_to_er_page
    slmc.go_to_er_landing_page
    slmc.er_patient_search(:pin => @@er_pin1)
    slmc.click_register_patient
    slmc.admit_er_patient(:org_code => "0173", :account_class =>  "WOMEN'S BOARD DEPENDENT").should be_true
  end
  it"Women's Board Member - Dependent - ER, Order Items" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin1)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin1)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Women's Board Member - Dependent - ER, Clnically Discharge Patient" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin1)
    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin1, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
  it"Women's Board Member - Dependent - ER, Add Guarantor" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin1)
    slmc.go_to_pba_action_page(:visit_no => @@visit_no, :page => "Update Patient Information" )
    slmc.click_new_guarantor
    slmc.pba_update_guarantor(:guarantor_type => "WOMEN'S BOARD", :guarantor_code => "WOMB001").should be_true
    slmc.click_submit_changes.should be_true
  end
  it"Women's Board Member - Dependent - ER, Standard Discharge Patient" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin1)
    slmc.go_to_pba_action_page(:visit_no => @@visit_no, :page => "Discharge Patient" )
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
  it"Women's Board Member - Dependent - ER, Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "WOMB001"
    slmc.skip_update_patient_information.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it"Women's Board Member - Dependent - ER, Check Discount Information Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f  * @promo_discount_non_senior
    @discount_promo = @@summary[:hospital_bill].to_f - @original_discount_promo
    @discount_class = (@discount_promo * 10).round.to_f / 100
    @total_hospital_bills = @discount_promo - @discount_class

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo+@discount_class)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end
  it"Women's Board Member - Dependent - ER, Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
end
