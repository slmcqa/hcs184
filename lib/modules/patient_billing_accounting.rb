#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/patient_billing_accounting_helper'
require File.dirname(__FILE__) + '/helpers/locators'

module PatientBillingAccounting
  include PatientBillingAccountingHelper
  include Locators::Philhealth
  include Locators::AdditionalRoomAndBoardCancellation

  #returns a boolean value if a search is successul
  #sample usage: object.pba_search(:pin => pin, :last_name = last_name, :no_result => true)
  def pba_search(options = {})
    type "criteria", options[:pin]
    click '//input[@type="radio" and @value="WithDischarge"]' if options[:with_discharge_notice]
    click "optDis" if options[:discharged]
    click "optAdm" if options[:admitted]
    click "optAll" if options[:all_patients] && (is_element_present('optAll'))
    click '//input[@type="submit" and @value="Search" and @name="search"]', :wait_for => :page
    sleep 2
    if is_element_present "css=#results>tbody>tr>td:nth-child(4)" #discount adjustment line#87
      visit_no = get_text("css=#results>tbody>tr>td:nth-child(4)").gsub(' ', '' )

      return visit_no
    end
    if options[:no_result]
      is_text_present("NO PATIENT FOUND")
    else
      is_text_present options[:last_name]
    end
  end
  # method used for er billing page and social service page
  def pba_search_1(options = {})
    type "criteria", options[:pin]
    click "filter" if options[:with_discharge_notice]
    click "filter1" if options[:discharged]
    click "filter2" if options[:admitted]
    click "filter3" if options[:all_patients] && (is_element_present('filter3'))
    click "search", :wait_for => :page
    sleep 2
    if is_element_present "css=#results>tbody>tr>td:nth-child(5)" #discount adjustment line#87
      visit_no = get_text("css=#results>tbody>tr>td:nth-child(5)").gsub(' ', '' )
      return visit_no
    end
    if options[:no_result]
      is_text_present("NO PATIENT FOUND")
    else
      is_text_present options[:last_name]
    end
  end
  def visit_number
    get_text("css=#results>tbody>tr>td:nth-child(4)").gsub(' ', '')
  end
  def visit_number_discount_adjusment
    get_text("css=#results>tbody>tr>td:nth-child(4)").gsub(' ', '')
  end
  def er_visit_number
    get_text("//html/body/div/div[2]/div[2]/div[4]/table/tbody/tr/td[4]").gsub(' ', '')
  end
  def go_to_page_using_reference_number(page, vn)
    select "userAction_#{vn}", "label=#{page}"
    click  "//input[@value='Submit']", :wait_for => :page
  end
  def go_to_page_using_visit_number(page, vn)
    select "id=userAction#{vn}", "label=#{page}"
    click 'css=td.submitButton>input[value="Submit"]', :wait_for => :page
  end
  def select_partial_discount_type(options={})
    click "optPartDiscAuto" if options[:automatic]
    click "optPartDiscMan" if options[:manual]
    click "//input[@type='button' and @onclick='submitPartialDiscount();' and @value='OK']", :wait_for => :page
    return true if is_text_present("Discount Information") && options[:manual]
    return get_text("css=#errorMessages") if is_element_present("css=#errorMessages") && (get_text("css=#errorMessages") != "")
  end
  def add_pf_amount(options = {})
    #select "admissionDoctors0.pfInstruction.code", "label=#{options[:pf_instruction].upcase}" if options[:pf_instruction]
    #type "admissionDoctors0.pfAmount", options[:pf_amount]
    type "css=#row>tbody>tr:nth-child(2)>td:nth-child(5)>span>input", options[:pf_amount]
    click "//input[@value='Submit Changes']", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/div[3]/div") == "The Patient Info was updated."
  end
  def select_guarantor
    click "guarantorId"
  end
  def click_guarantor_to_update
    click "guarantorId"
    click "link=Update Guarantor", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/div[12]/h2/b") == "Add/Edit Guarantor"
  end
  def click_new_guarantor
    click "link=New Guarantor", :wait_for => :page
    sleep 5
    get_text("css=div.commonForm>h2>b") == "Add/Edit Guarantor"
  end
  def click_update_guarantor
    click "updateLink", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/div[12]/h2/b") == "Add/Edit Guarantor"
    sleep 2
  end
  def click_delete_guarantor
    code = get_text("//html/body/div/div[2]/div[2]/div[4]/table/tbody/tr/td[2]")
    click "deleteLink"
    get_confirmation() == "Are you sure you want to delete this guarantor?"
    choose_ok_on_next_confirmation()
    sleep 10
    !is_text_present(code)
  end
  def pba_update_account_class(account_class)
    select "accountClass", "label=#{account_class}"
    submit_button = is_element_present( "//input[@value='Submit Changes']") ?  "//input[@value='Submit Changes']" :  '//input[@type="submit" and @value="Save"]'
    click(submit_button, :wait_for => :page)
    if is_element_present("successMessages")
      get_text("successMessages")
    elsif is_element_present("errorMessages")
      get_text("errorMessages")
    end
  end
  def pba_update_guarantor(options = {})
    select "guarantorType", "label=#{options[:guarantor_type]}" if options[:guarantor_type]
    if options[:guarantor_code]
      if options[:guarantor_type] == 'INDIVIDUAL'
        type "guarantor.guarantorName", options[:name]
      else
        click "id=findGuarantor" if options[:guarantor_code]
        if options[:guarantor_type] == 'EMPLOYEE'
          type 'employee_entity_finder_key', options[:guarantor_code]
          click "//input[@value='Search' and @type='button' and @onclick='EF.search();']"
        elsif options[:guarantor_type] == 'DOCTOR'
          type 'id=ddf_entity_finder_key', options[:guarantor_code]
          #click "//input[@value='Search']"
          click 'css=input[type="button"]'

        else
          type "bp_entity_finder_key", options[:guarantor_code]
          click "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']"
        end
        sleep 5
        if is_element_present("link=#{options[:guarantor_code]}")
          click "link=#{options[:guarantor_code]}" if options[:guarantor_code]
        else
          click("//div[@title='Click to select.']")
        end
        sleep 5
      end
    end
    click "phFlag1" if options[:philhealth]
    if options[:include_pf]
      click "includePfTag"
      sleep 10
      click "chkCovered0", :wait_for => :element, :element => 'loa.maximumPfAmount' if options[:include_pf_doctor]
      type 'loa.maximumPfAmount', options[:max_pf_coverage]
    end
    type "loa.loaNo", (options[:loa] if options[:loa]) || Time.new.strftime("%Y%m%d")
    sleep 2
    type "loa.maximumAmount", options[:loa_max] if options[:loa_max]
    type "loa.percentageLimit", options[:loa_percent] if options[:loa_percent]
    click "_submit", :wait_for => :page
    if (is_element_present("link=New Guarantor")) && (is_text_present(options[:loa]) if options[:loa])
      return true
    elsif is_element_present("link=New Guarantor")
      return true
    else
      return get_text('//*[@id="errorMsg"]')
    end
    sleep 2
  end
  def delete_guarantor(pin)
    self.pba_search(:pin => pin)
    go_to_page_using_visit_number("Update Patient Information", self.visit_number)
    click "guarantorId"
    click "deleteLink"
    get_confirmation
  end
  def click_submit_changes
    submit_button = is_element_present("//input[@value='Submit Changes' and @type='submit']") ?  "//input[@value='Submit Changes' and @type='submit']" :  '//input[@type="submit" and @value="Save"]'
    click(submit_button, :wait_for => :page)
    is_text_present("The Patient Info was updated.")
  end
  ## Payment Data Entry
  def get_hospital_bill_amount
    get_text('//*[@id="hospitalBills"]').gsub(',','')
  end
  def get_room_charges_amount
    get_text('//*[@id="roomCharges"]').gsub(',','')
  end
  def get_adjustments_amount
    get_text("adjustments").gsub(',','')
  end
  def get_philhealth_amount
    get_text('//*[@id="philhealth"]').gsub(',','')
  end
  def get_discount_amount
    get_text('//*[@id="discounts"]').gsub(',','')
  end
  def get_ewt_amount
    get_text("ewt").gsub(',','')
  end
  def get_total_gift_check
    get_text("totalGcAmount").gsub(',','') if is_element_present("totalGcAmount")
  end
  def get_payments_amount
    get_text("hospitalPayments").gsub(',','')
  end
  def get_charged_amount
    get_text('//*[@id="chargedAmount"]').gsub(',','')
  end
  def get_social_service_coverage
    get_text("ssCoverage").gsub(',','') if is_element_present("ssCoverage")
  end
  def get_total_hospital_bills
    get_text("totalHospitalBills").gsub(',','')
  end
  def get_pf_amount
    get_text('//*[@id="pfAmount"]').gsub(',','')
  end
  def get_pf_payment_amount
    get_text('//*[@id="pfPayments"]').gsub(',','')
  end
  def get_pf_charged_amount
    get_text('//*[@id="pfCharged"]').gsub(',','')
  end
  def get_total_amount
    get_text('//*[@id="totalAmountDue"]').gsub(',','')
  end
  def get_total_hospital_bill_amount
    get_text('//*[@id="totalHospitalBills"]').gsub(',','')
  end
  def get_total_payments_amount
    get_text('paymentTotalPayments').gsub(',','')
  end
  def get_balance_due
    get_text('//*[@id="balanceDueSpan"]').gsub(',','')
  end
  def get_billing_details_from_payment_data_entry
    hb = get_hospital_bill_amount
    rc = get_room_charges_amount
    adj = get_adjustments_amount
    phil = get_philhealth_amount
    disc = get_discount_amount
    ewt = get_ewt_amount
    gc = get_total_gift_check
    py = get_payments_amount
    ca = get_charged_amount
    ssc = get_social_service_coverage
    thb = get_total_hospital_bills
    pfa = get_pf_amount
    pfp = get_pf_payment_amount
    pfc = get_pf_charged_amount
    tad = get_total_amount
    tp = get_total_payments_amount
    bd = get_balance_due
    return {
      :hospital_bill => hb,
      :room_charges => rc,
      :adjustments => adj,
      :philhealth => phil,
      :discounts => disc,
      :ewt => ewt,
      :gift_check => gc,
      :payments => py,
      :charged_amount => ca,
      :social_service_coverage => ssc,
      :total_hospital_bills => thb,
      :pf_amount => pfa,
      :pf_payments => pfp,
      :pf_charged =>pfc,
      :total_amount_due => tad,
      :total_payments => tp,
      :balance_due => bd
    }
  end
  def verify_total_amount_due(loa)
    #charges
    hospital_bill = get_text('//*[@id="hospitalBills"]').gsub(',','').to_f
    room_charges = get_text('//*[@id="roomCharges"]').gsub(',','').to_f
    pf_amount = get_text('//*[@id="pfAmount"]').gsub(',','').to_f

    #deductions
    philhealth = get_text('//*[@id="philhealth"]').gsub(',','').to_f
    discount = get_text('//*[@id="discounts"]').gsub(',','').to_f

    total_amount_due = ((hospital_bill + room_charges + pf_amount) - (philhealth + discount)) * (loa.to_f/100.00)

    if (get_text('//*[@id="totalAmountDue"]').gsub(',','').to_f == total_amount_due)
      return total_amount_due
    else
      return false
    end
  end
  def verify_payment_details(options={})
    #charges
    hospital_bill = get_text('//*[@id="hospitalBills"]').gsub(',','').to_f
    room_charges = get_text('//*[@id="roomCharges"]').gsub(',','').to_f
    pf_amount = get_text('//*[@id="pfAmount"]').gsub(',','').to_f

    #deductions
    philhealth = get_text('//*[@id="philhealth"]').gsub(',','').to_f
    discount = get_text('//*[@id="discounts"]').gsub(',','').to_f
    charged_amount = get_text('//*[@id="chargedAmount"]').gsub(',','').to_f
    pf_payment = get_text('//*[@id="pfPayments"]').gsub(',','').to_f
    pf_charge = get_text('//*[@id="pfCharged"]').gsub(',','').to_f

    if options[:total_amount_due]
      amount_due = (((hospital_bill + room_charges)  - discount) * (options[:loa].to_f/100.00) + (pf_amount - (pf_charge + pf_payment)))
      if (get_text('//*[@id="totalAmountDue"]').gsub(',','').to_f == amount_due)
        return amount_due
      else
        return false
      end
    elsif options[:total_hosp_bills]
      amount = ((hospital_bill + room_charges) - (philhealth + discount + charged_amount))
      return amount if (get_text('//*[@id="totalHospitalBills"]').gsub(',','').to_f == amount)

    elsif options[:pf_bal]
      pf_charged = pf_amount * (options[:loa].to_f/100.0)
      pf_balance = pf_amount - pf_charged
      return pf_balance if (get_text('//*[@id="pfCharged"]').gsub(',','').to_f == pf_charged)

    elsif options[:charged_amount]
      charged_amount = ((hospital_bill + room_charges) - discount) * (options[:loa].to_f/100.00)
      return charged_amount if (get_text('//*[@id="chargedAmount"]').gsub(',','').to_f == charged_amount)

    elsif options[:total_balance]
      total_balance = ((hospital_bill + room_charges) - (philhealth + discount + options[:charge_amount])) + (pf_amount - (pf_charge + pf_payment))
      return total_balance if (get_text('//*[@id="balanceDueSpan"]').gsub(',','').to_f == total_balance)
    end
  end
  def pba_full_payment(options={})
    sleep 5
    click "hospitalPayment"
    value = get_text("//*[@id=\"totalAmountDue\"]").gsub(",","")
    type "cashBillAmount", value
    if value.match ','
      value = value.split(',')
      cash_payment = (value[0] + value[1]).to_f
    else cash_payment = value.to_f
    end
    click 'cashPaymentMode1' if !(is_checked("//*[@id=\"cashPaymentMode1\"]"))
    sleep 1
    type "id=cashAmountInPhp",  options[:cash] || cash_payment
    sleep 3
    type "cashBillAmount", options[:cash] || cash_payment
    click "save", :wait_for => :page
    a = is_element_present("//input[@value='Print OR']")
    click("//input[@value='Print OR']", :wait_for => :page)
    return a
  end
  def my_pba_full_payment(options={})
    sleep 5
    click "hospitalPayment"
   value = get_text('//*[@id="totalHospitalBills"]').gsub(",","")
   # fvalue = get_text("//*[@id=\"totalAmountDue\"]").gsub(",","")
#    value = fvalue
#    puts "value = #{fvalue}"
    pf_charge =  get_text('//*[@id="pfCharged"]').gsub(",","")
  #  click "hospitalPayment"
    type "cashBillAmount", value
    if value.match ','
      value = value.split(',')
      cash_payment = (value[0] + value[1]).to_f
    else cash_payment = value.to_f
    end
    click 'cashPaymentMode1' if !(is_checked("//*[@id=\"cashPaymentMode1\"]"))
    sleep 1
    type "id=cashAmountInPhp",  options[:cash] || cash_payment
    sleep 3
    type "cashBillAmount", options[:cash] || cash_payment

#    click "save", :wait_for => :page if is_element_present("save")
    click "name=save", :wait_for => :page if is_element_present("name=save")
    
  if options[:pf_amount]
                 sleep 6
                  type "id=admissionDoctorsPayment0.pfPayment", options[:pf_amount] || pf_charge
                  sleep 3
                  click 'id=cashPaymentMode1' if !(is_checked("//*[@id=\"cashPaymentMode1\"]"))
                  sleep 1
                  type "id=cashAmountInPhp",  options[:pf_amount] || pf_charge
                  sleep 3
                  type "cashBillAmount", options[:pf_amount] || pf_charge
            #      click "save", :wait_for => :page if is_element_present("save")
                  click "name=save", :wait_for => :page if is_element_present("name=save")

  end

    a = is_element_present("//input[@value='Print OR']")
    click("//input[@value='Print OR']", :wait_for => :page)
    return a
  end
  def submit_payment
    click "save", :wait_for => :page
    is_element_present "//input[@value='Print SOA']"
  end
  def discharge_patient(pin)
    self.pba_search(:pin => pin)
    go_to_page_using_visit_number("Discharge Patient", self.visit_number)
    click 'css=td.submitButton>input[value="Submit"]', :wait_for => :page
    is_text_present("Discharge Successful")
  end
  def generate_soa_for_pin(pin)
    self.pba_search(:pin => pin, :discharged => true)
    go_to_page_using_visit_number("Generation of SOA", self.visit_number_discount_adjusment)
    is_text_present("Generation of Statement of Account")
    is_text_present(pin)
  end
  def click_generate_official_soa
    sleep 10
    click "//input[@value='Generate Official SOA']" if is_element_present("//input[@value='Generate Official SOA']")
    sleep 6
    click "css=input[type=\"button\"]" if is_element_present("css=input[type=\"button\"]")
    sleep 6
    click "_submit", :wait_for => :element, :element => "popup_ok"
    sleep 6
    click "popup_ok" if is_element_present("popup_ok")
    sleep 6
    click "id=tagDocument", :wait_for => :page if is_element_present("id=tagDocument")
    sleep 6

    a = is_text_present "The SOA was successfully updated with printTag = 'Y'."
    b = is_text_present("Patient Billing and Accounting Home")
    return a & b
  end
  def click_print_unofficial_soa(options={})
    click "//input[@value='Print Unofficial SOA']"
    sleep 1
    if options[:soa_type] == "Itemized"
      click'itemizedRadio'
    else options[:soa_type] == "By Department"
      click'perDeptRadio'
    end
    if options[:with_pf]
      click'includePF'
    end
    click "_submit", :wait_for => :page
    is_text_present("Patient Billing and Accounting Home") || is_element_present("//input[@name='myButtonGroup' and @value='Print SOA']")
  end
  def generate_unofficial_soa(pin)
    go_to_patient_billing_accounting_page
    patient_pin_search(:pin => pin)
    @visit_number = go_to_page_using_visit_number("Generation of SOA", self.visit_number)
    click 'css=td.submitButton>input[value="Submit"]'
    @hospital_bills = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div/div[2]").split(" ")[1].gsub(",", "").to_f
    @room_and_bed = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[2]/div[2]").split(" ")[1].gsub(",", "").to_f
    @pf_amount = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[3]/div[2]").split(" ")[1].gsub(",", "").to_f
    @discounts = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[7]/div[2]").split(" ")[1].gsub(",", "").to_f
    @payments = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[9]/div[2]").split(" ")[1].gsub(",", "").to_f
    @balance_due = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[10]/div[2]/b").split(" ")[1].gsub(",", "").to_f
    click "//div[@id='main']/div[5]/div"
    self.click_print_unofficial_soa
    # hospital_bills + room_and_bed + pf_amount -discount - payments = balance_due
    @hospital_bills + @room_and_bed + @pf_amount - @discounts - @payments == @balance_due
    return @visit_number && @pf_amount && @balance_due
  end
  def generates_soa_after_pf_payment(pin)
    go_to_patient_billing_accounting_page
    pba_search(:pin => pin, :discharged => true)
    @visit_number = go_to_page_using_visit_number("Generation of SOA", self.visit_number_discount_adjusment)
    hospital_bills = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div/div[2]").split(" ")[1].gsub(",", "").to_f
    room_and_bed = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[2]/div[2]").split(" ")[1].gsub(",", "").to_f
    pf_amount = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[3]/div[2]").split(" ")[1].gsub(",", "").to_f
    discounts = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[7]/div[2]").split(" ")[1].gsub(",", "").to_f
    payments = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[9]/div[2]").split(" ")[1].gsub(",", "").to_f
    balance_due = get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[10]/div[2]/b").split(" ")[1].gsub(",", "").to_f
    click "//div[@id='main']/div[5]/div"
    self.click_print_unofficial_soa
    hospital_bills + room_and_bed - discounts + payments - pf_amount == balance_due
    return balance_due
  end
  def verify_error_message_discharge_without_payment(pin)
    patient_pin_search(:pin => pin)
    go_to_page_using_visit_number("Discharge Patient", self.visit_number_discount_adjusment)
    click "dischargeType1"
    click "//input[@name='_submit']", :wait_for => :page
    return is_text_present("Please settle outstanding PF amount.")
  end
  def pba_pf_payment(options ={})
        click "deposit" if options[:deposit]
        click "pfPayment"
        sleep 10
        type "admissionDoctorsPayment0.pfPayment", options[:pf_amount]
        click "cashPaymentMode1" if !(is_checked("//*[@id=\"cashPaymentMode1\"]"))
        sleep 3
        type("id=cashAmountInPhp", options[:pf_amount])
        sleep 3
        type "cashBillAmount", options[:pf_amount]
        sleep 5
        click "save", :wait_for => :page
        click "//input[@value='Print OR (PF)']", :wait_for => :page
        is_element_present "//input[@value='Go To Landing Page']"
  end
  #added by hanna for HB deposit
  def pba_hb_deposit_payment(options ={})
    click "deposit" if options[:deposit]
    click "hospitalPayment"
    sleep 10
    click "cashPaymentMode1" if !(is_checked("//*[@id=\"cashPaymentMode1\"]"))
    sleep 3
    type "cashBillAmount", options[:cash]
    type "cashAmountInPhp", options[:cash]
    click "save", :wait_for => :page
    is_element_present "//input[@value='Go To Landing Page']"
  end
  #HB deposit
  def print_or
    click("popup_ok", :wait_for => :page) if is_element_present("popup_ok")
    a = is_text_present("The (PF)Official Receipt print tag has been set as 'Y'.")
    click "//input[@value='Print OR']"
    sleep 10
    click("popup_ok", :wait_for => :page) if is_element_present("popup_ok")
    b = is_text_present("The Official Receipt print tag has been set as 'Y'.")
    return a && b
  end
  def get_or_number
    location = get_location()
    array1 = location.split('=')
    array2 = array1[2].split('&')
    return array2[0]
  end
  def print_or_pf_and_soa(options = {}) #HB is 100% covered excluding PF
#    click"//html/body/div/div[2]/div[2]/form/div/input", :wait_for => :page -> can be use if next stmt. will not work
    click "//input[@value='Print OR (PF)']", :wait_for => :page
    click "popup_ok", :wait_for => :page if is_element_present"popup_ok"
    is_text_present( "The(PF)Official Receipt print tag has been set as 'Y'.")
    print_soa
    click("//input[@value='Generate Official SOA']")
    if options[:soa_type] == "Itemized"
      click('itemizedRadio','Itemized')
    else options[:soa_type] == "By Department"
      click('perDeptRadio','By Department')
    end
    click("//input[@value='Submit']")
    is_element_present("popup_message").should be_true
    click "popup_ok",:wait_for => :page
    click "//input[@value='Print Clearance']",:wait_for => :page
    click "//input[@value='Go To Landing Page']",:wait_for => :page
  end
  def print_soa
    click "//input[@value='Print SOA']", :wait_for => :page
    is_text_present("Generation of Statement of Account")
  end
  def print_clearance
    click "//input[@value='Print Clearance']", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/div[3]/div") == "Discharge clearance printed."
  end
  def go_to_philhealth_outpatient_computation(options={})
    sleep 1
    if options[:pba_special_ancillary]
      click "link=PBA Special Ancillary", :wait_for => :page
    elsif options[:philhealth_multiple_session]
      click "link=PhilHealth Multiple Session", :wait_for => :page
    else
      click "link=PhilHealth DAS/SPU", :wait_for => :page
    end
    is_element_present "searchString"
  end
  def pba_pin_search(options={})
    type "searchString", options[:pin]
    click "search", :wait_for => :page
    pin = return_original_pin(options[:pin].to_s)
    is_text_present(pin)
  end
  def click_philhealth_link(options={})
    sleep 3
    if options[:visit_no]
     # me = "//a[@href='/pba/philhealth/outPatientSearch.html?visitNo=#{options[:visit_no]}&pin=#{options[:pin]}']"
#      me ="//a[contains(@href, '/pba/philhealth/outPatientSearch.html?visitNo=#{options[:visit_no]}&pin=#{options[:pin]}')]"
#      unless is_element_present(me)
#        #click("link=Last »", :wait_for => :page)
#        click("link=Next ›")# :wait_for => :page)
#        sleep 6
#
#      end
      type "name=searchString", options[:pin]
      sleep 3
      type "name=visitNoSearchParam", options[:visit_no]
      sleep 3
      click "css=#clearButtonGroup > input[name=\"search\"]"
      sleep 6
      click "link=PhilHealth", :wait_for => :page
    #  click me, :wait_for => :page
      is_text_present("PhilHealth Reference No.:")
    else
      click "link=PhilHealth", :wait_for => :page
      is_text_present("PhilHealth Reference No.:")
    end
  end
  def click_latest_philhealth_link_for_outpatient
    sleep 3
#    while is_element_present("link=Next ›")
#        click "link=Next ›", :wait_for => :page
#    end
if is_element_present("link=Last »")
        click "link=Last »"
        sleep 3
        puts "580"
        count = get_xpath_count("//html/body/div/div[2]/div[2]/div[4]/div/table/tbody/tr")
        puts "582"
        click "//table[@id='results']/tbody/tr[#{count}]/td[5]/div/a", :wait_for => :page
        puts "584"
else
   count = get_xpath_count("//html/body/div/div[2]/div[2]/div[4]/div/table/tbody/tr")
  click "//table[@id='results']/tbody/tr[#{count}]/td[5]/div/a", :wait_for => :page
end

  end
  def go_to_landing_page
    click "//input[@value='Go To Landing Page']", :wait_for => :page
    is_element_present "param"
  end
  def select_discharge_patient_type(options = {})
    if options[:type] == "STANDARD"
      click "dischargeType1"
    elsif options[:type] == "DAS"
      click "dischargeType2"
      sleep 3

    end
    click "//input[@name='_submit']"
    sleep 40
   # wait_for_page_to_load "5000" if options[:type] == "STANDARD" # comment when @stlukes

#    wait_for_element("//html/body/div/div[2]/div[2]/div[4]/h2/b") if options[:type] == "STANDARD"

    sleep Locators::NursingGeneralUnits.waiting_time if options[:type] == "DAS"
 #   click("//input[@value='CONTINUE' and @name='YES']", :wait_for => :page) if (options[:type] == "DAS" && is_visible("//input[@value='CONTINUE' and @name='YES']"))
 if (options[:type] == "DAS")
    click("id=postRB");
    click("id=wholeDayRB");
    click("name=YES",:wait_for => :page);
    sleep 10
    if is_text_present("Patients for DEFER should be processed before end of the day")
          return true
    else
          if is_text_present("Only fully covered")
                  click "dischargeType2"
                  sleep 3
                  click "//input[@name='_submit']"
                  sleep 40
                  click("id=postRB");
                  click("id=wholeDayRB");
                  click("name=YES",:wait_for => :page);
                  sleep 10
                  if is_text_present("Patients for DEFER should be processed before end of the day")
                      return true
                  else
                      return false
                  end
          else
                  return true
          end
    end
    sleep 10
 else
         if is_element_present("//html/body/div/div[2]/div[2]/div[4]/h2/b")
                return true
         else
                return false
         end
 end

    if options[:pf_paid]
      is_element_present("formAction")
    else
      is_element_present("//input[@value='Print SOA']")
    end
  end
  def update_patient_or_guarantor_info(options={})
    click "formAction", :wait_for => :page if is_element_present("formAction")
    if is_text_present("Patient has no coverage. Please specify maximum amount or percentage limit.")
      click_guarantor_to_update
      select("guarantorType", options[:guarantor_type]) if options[:guarantor_type]
      type "loa.loaNo", (options[:loa] if options[:loa]) || Time.new.strftime("%Y%m%d")
      percent = "100" || options[:percent]
      type "loa.percentageLimit", percent
      click "_submit", :wait_for => :page
      click "formAction", :wait_for => :page
    end
    sleep 5
    (is_text_present("Patient Billing and Accounting Home › Additional Room and Board Cancellation")) || (get_text("//html/body/div/div[2]/div[2]/form/div[2]/div/div/label") == "PhilHealth Reference No.:")
  end
  def room_and_board_cancellation(options={})
    if options[:skip]
      click "skipButton", :wait_for => :page if is_element_present("skipButton")
      is_text_present("Patient Billing and Accounting Home › PhilHealth")
    elsif options[:edit]
      click "submitButton", :wait_for => :page
    end
  end
  def input_philhealth_reference(options={})
    select "claimType", "label=#{options[:claim_type]}" if options[:claim_type]
    click "btnDiagnosisLookup"
    type "icd10_entity_finder_key", options[:diagnosis] if options[:diagnosis]
    click "//input[@value='Search' and @type='button' and @onclick='Icd10Finder.search();']"
    sleep 3
    click "link=CHOLERA" || "link=#{options[:diagnosis]}" if options[:diagnosis]
    sleep 2
    type "memberInfo.membershipID", options[:philhealth_id] || "12345"
    type "memberInfo.memberCity", "City"
    type "memberInfo.memberProvince", "Province"
    select "memberInfo.memberCountry", "label=PHILIPPINES"
    type "memberInfo.memberPostalCode", "1234"
    type "memberInfo.employerName", "Employer"
    type "memberInfo.employerAddress.address", "Address"
    type "memberInfo.employerAddress.city", "City"
    type "memberInfo.employerAddress.province", "Province"
    select "memberInfo.employerAddress.country", "label=PHILIPPINES"
    type "memberInfo.employerAddress.postalCode", "1234"
  end
  def philhealth_page(options={})
    if options[:skip]
      click "btnSkip", :wait_for => :page
      if options[:required_philhealth]
        get_text('//*[@id="*.errors"]').include? "Cannot skip, Philhealth required by a guarantor"# if is_element_present("*.errors")
      elsif options[:skip_compute]
        get_text('//*[@id="*.errors"]').include? "Member ID is a required field.\nEmployer Name is a required field.\nEmployer Number and Street is a required field.\nICD10 is required when saving PhilHealth form."
      else
        is_text_present("Discount Information")
      end
    elsif options[:compute]
      #click "btnCompute"
      click "id=btnCompute"

      sleep 25
    end
  end
  def discount_information
    click "//input[@value='Skip']", :wait_for => :page
    is_element_present("Generation of Statement of Account")
  end
  def proceed_with_payment
    click "save", :wait_for => :page
    is_element_present "//input[@value='Print OR']"
  end
  def discharge_to_payment(options={})
    sleep 2
    (update_patient_or_guarantor_info options) if is_element_present('//input[@type="submit" and @name="formAction" and @value="Skip"]')
    click "skipButton", :wait_for => :page if is_element_present("skipButton")
    c3 = (get_text("//html/body/div/div[2]/div[2]/form/div[2]/div/div/label") == "PhilHealth Reference No.:")
    if is_text_present("PhilHealth Reference No.:")
         c3 = true
    else
        c3 = false
    end
    
    click "btnSkip", :wait_for => :page
    # require philhealth information if EMPLOYEE guarantor is 'philhealth required'
    if options[:philhealth] && is_text_present("PhilHealth Reference No.:")
                if is_text_present("ESTIMATE")
                          click "id=btnSave"
                          sleep 3

                              if is_confirmation_present
                                      get_alert() =~ /^Please click the Compute button to apply the computation of Philhealth claim./
                                      choose_ok_on_next_confirmation()
                                      puts "just click allerthere"
                                      sleep 3
                                      click "id=btnCompute"
                                      sleep 10
                                      click "id=btnSave"
                                      sleep 10
                                      if is_text_present("FINAL")
                                            click "btnSkip", :wait_for => :page
                                            c4 = is_text_present("Discount Information")
                                      end
                                    end
                else
                          get_text('//*[@id="*.errors"]').include? "Member ID is a required field.\nEmployer Name is a required field.\nEmployer Number and Street is a required field.\nICD10 is required when saving PhilHealth form." if is_element_present('//*[@id="*.errors"]')
                          click "btnDiagnosisLookup"
                          type "icd10_entity_finder_key", options[:diagnosis] if options[:diagnosis]
                          click "//input[@value='Search' and @type='button' and @onclick='Icd10Finder.search();']"
                          sleep 3
                          click "link=CHOLERA" || "link=#{options[:diagnosis]}" if options[:diagnosis]
                          sleep 2
                          type "memberInfo.membershipID", "12345"
                          type "memberInfo.memberCity", "City"
                          type "memberInfo.memberProvince", "Province"
                          select "memberInfo.memberCountry", "label=PHILIPPINES"
                          type "memberInfo.memberPostalCode", "1234"
                          type "memberInfo.employerName", "Employer"
                          type "memberInfo.employerAddress.address", "Address"
                          type "memberInfo.employerAddress.city", "City"
                          type "memberInfo.employerAddress.province", "Province"
                          select "memberInfo.employerAddress.country", "label=PHILIPPINES"
                          type "memberInfo.employerAddress.postalCode", "1234"
                          click "btnSkip", :wait_for => :page
                          c4 = is_text_present("Discount Information")
                end
    else
      c4 = is_text_present("Discount Information")
    end
    click "//input[@value='Skip']", :wait_for => :page
    c7 = is_text_present("Generation of Statement of Account")
    click "submitButton", :wait_for => :page
    sleep Locators::NursingGeneralUnits.waiting_time
    sleep 60
    value = get_text("//*[@id=\"totalAmountDue\"]")
    if is_element_present("popup_message")
      click "popup_ok"
      sleep Locators::NursingGeneralUnits.waiting_time
      amount = get_value "cashAmountInPhp"
      type "admissionDoctorsPayment0.pfPayment", amount
      click "cashPaymentMode1"
      sleep 5
      type "cashBillAmount", amount
      click'//input[@value="Proceed with Payment"]', :wait_for => :page
    else
      if value.to_i > 0
        sleep Locators::NursingGeneralUnits.waiting_time
        type "cashBillAmount", value
        if value.match ','
          cash_payment = (value.gsub(',','')).to_f
          click 'cashPaymentMode1' if !(is_checked("//*[@id=\"cashPaymentMode1\"]"))
          sleep 1
          type "cashBillAmount", cash_payment
        elsif value.to_i <= 0
        else
          cash_payment = value.to_f
          click 'cashPaymentMode1' if !(is_checked("//*[@id=\"cashPaymentMode1\"]"))
          sleep 1
          type "cashBillAmount", cash_payment
        end
        # pass the amount from soa page
        if is_element_present("admissionDoctorsPayment0.pfPayment")
          pf_amount = get_text("css=#pfDetailsDiv>table>tbody>tr>td:nth-child(2)").gsub(",","")
          type("admissionDoctorsPayment0.pfPayment", pf_amount)
        end
      end
    end
    click "save", :wait_for => :page if is_element_present("save")
    c6 = is_element_present "//input[@value='Print OR']"
    return true if is_text_present("Patients for DEFER should be processed before end of the day")
    return (c3 && c4 && c6 && c7) if options[:discount_rate] and options[:discount_scheme]
    return (c3 && c4 && c6 && c7) if options[:discount_rate] #deleted c2 since it only returns to update patient page
  end
  # pba discharge patient not concerning whether it is standard or das
  def discharge_patient_either_standard_or_das
    result = select_discharge_patient_type(:type => "DAS")
    if result == false
      select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
      return true if discharge_to_payment == true
    else
      return true
    end
  end
  def pba_defer_patient
    type "reason", "reason"
    type "remarks", "remarks"
    click "//input[@name='_submit']", :wait_for => :page
    is_text_present("Defer Successful")
  end
  def add_discount(options={}) # discount, discount_type, discount_rate, discount_scope
    sleep 6
    if is_text_present("Discounts")
      if options[:discount_type] == "Fixed"
        select "discountType", "label=#{options[:discount]}"
        sleep 2
        type "id=endorsed", "SELENIUM TESTING"
        sleep 2
        type "id=approved", "SELENIUM TESTING"
        sleep 2
        select "discountScopeField", "label=#{options[:discount_scope]}"
        if options[:discount_scope] == "PER DEPARTMENT"
          select("discountScopeField","PER DEPARTMENT")
          click("deptBtn", :wait_for => :element, :element => "orderGroupDiscountFinderForm")
          click('//input[@type="button" and @onclick="DF.search();"]', :wait_for => :element, :element => "css=#finder_table_body>tr.even>td>div")
          click("//div[@title='Click to select.']")
          sleep 1
         elsif options[:discount_scope] == "PER SERVICE"
          select("discountScopeField","PER SERVICE")
          click("serviceBtn", :wait_for => :element, :element => "orderDetailDiscountFinderForm")
          click('//input[@type="button" and @onclick="ODF.search();"]', :wait_for => :element, :element => "css=#odf_finder_table_body>tr.even>td>div")
          click("//div[@title='Click to select.']")
        end
        click "optDiscFixed"
        type "fixedType", options[:discount_rate]
        click("addScopeBtn")
        sleep 5
        get_confirmation() =~ /^Do you want to exclude item\(s\) from Patient's View Order Charge List[\s\S]$/ if is_confirmation_present
        choose_cancel_on_next_confirmation() if options[:cancel_exclude]
        choose_ok_on_next_confirmation()

      else # percentage discount
        select "discountType", "label=#{options[:discount]}"
        sleep 1
        type "id=endorsed", "SELENIUM TESTING"
        sleep 2
        type "id=approved", "SELENIUM TESTING"
        sleep 2
        select "discountScopeField", "label=#{options[:discount_scope]}"
        click "optDiscPercent"
        sleep 5
        type "percentType", options[:discount_rate]
        click("addScopeBtn")
        sleep 5
        get_confirmation() =~ /^Do you want to exclude item\(s\) from Patient's View Order Charge List[\s\S]$/ if is_confirmation_present
        choose_cancel_on_next_confirmation() if options[:cancel_exclude]
        choose_ok_on_next_confirmation()
      end
      sleep 200
      validator = is_element_present("//input[@value='Continue']")
      click("//input[@value='Continue']") if is_visible("//input[@value='Continue']")
     sleep 400
      wait_for(:wait_for => :element, :element => "css=#gen_table_body>tr")
      sleep 5
      click "//input[@value='Close Window']" if options[:close_window]
      sleep 5
      if options[:employee_discount]
        alert = get_alert
        click'//input[@type="button" and @value="Cancel"]'
      end
      return alert if options[:employee_discount]
      click "saveBtn", :wait_for => :page if options[:save]
      sleep 5
      return validator if options[:validator]
      is_text_present("Discount Information")
    end
  end
  #exclude 1 item only from discount
  def exclude_item(options={})
    sleep 40

    count = get_css_count("css=#gen_table_body>tr")

    if options[:all]
      count.times do |rows|
        click("css=#gen_table_body>tr:nth-child(#{rows + 1})>td:nth-child(12)>input")
      end
    end

    if options[:drugs]
      count.times do |rows|
        my_row = get_text("css=#gen_table_body>tr:nth-child(#{rows + 1})>td:nth-child(3)")
        if my_row == "DRUGS / MEDICINE"
          stop_row = rows
          click("css=#gen_table_body>tr:nth-child(#{stop_row + 1})>td:nth-child(12)>input")
        end
      end
    end

    if options[:ancillary]
      count.times do |rows|
        my_row = get_text("css=#gen_table_body>tr:nth-child(#{rows + 1})>td:nth-child(3)")
        if my_row == "ANCILLARY / PROCEDURE"
          stop_row = rows
          click("css=#gen_table_body>tr:nth-child(#{stop_row + 1})>td:nth-child(12)>input")
        end
      end
    end

    if options[:supplies]
      count.times do |rows|
        my_row = get_text("css=#gen_table_body>tr:nth-child(#{rows + 1})>td:nth-child(3)")
        if my_row == "SUPPLIES"
          stop_row = rows
          click("css=#gen_table_body>tr:nth-child(#{stop_row + 1})>td:nth-child(12)>input")
        end
      end
    end

    if options[:room_and_board]
      count.times do |rows|
        my_row = get_text("css=#gen_table_body>tr:nth-child(#{rows + 1})>td:nth-child(3)")
        if my_row == "ROOM AND BOARD"
          stop_row = rows
          click("css=#gen_table_body>tr:nth-child(#{stop_row + 1})>td:nth-child(12)>input")
        end
      end
    end

    if options[:save]
      click("//input[@value='Close Window']")
      sleep 40
      return get_alert if is_alert_present
      click("saveBtn")
      sleep 40
      sleep 10
      
#      sleep 400

      a = is_text_present("Discount Information")
      b = is_text_present("has been saved successfully.")
      return a && b
    end
  end
  def philhealth_computation(options ={})
    if options[:cancel]
              sleep 3
              click '//*[@id="btnCancel"]'
              sleep 3
              click "id=btnCancel"
              sleep 3
              type "id=reasonText", "asdasdas"
              sleep 3
              click "xpath=(//input[@name='btnOK'])[3]"
              sleep 3
              phil_ref = ("//html/body/div/div[2]/div[2]/form/div[2]/div/div/label").gsub("PhilHealth Reference No.: ","")
              get_confirmation() =~ /^Continue with the cancellation of the Philhealth Reference number #{phil_ref}[\s\S]$/ if is_confirmation_present
              sleep 3
              choose_ok_on_next_confirmation()
              sleep 3
              click "id=btnRecompute"
              sleep 6
    end
    if options[:rvu_code] !=nil
              options[:case_rate_type] = "SURGICAL"
              options[:case_rate] = options[:rvu_code]
#    else
#              options[:case_rate_type] = "MEDICAL"
              #options[:case_rate] =  ""
    end

#    if options[:special_unit]
#            options[:case_rate_type] = false
#    end
    diagnosis = options[:diagnosis] || "GLAUCOMA"
    sleep 2
    is_text_present "PhilHealth Reference No.:"
    if options[:edit]
      click "btnEdit"
      click "id=btnClear"
      sleep 5
    end
    select "claimType", "label=#{options[:claim_type]}" if options[:claim_type] if is_visible "claimType"
    click "btnDiagnosisLookup", :wait_for => :element, :element => "icd10_entity_finder_key"
    type "icd10_entity_finder_key", diagnosis
    click "//input[@value='Search' and @type='button' and @onclick='Icd10Finder.search();']", :wait_for => :element, :element => "link=#{diagnosis}"
    click "link=#{diagnosis}", :wait_for => :not_visible, :element => "link=#{diagnosis}"
    sam = "med_case_type N/A"
    medical_case_type = options[:medical_case_type] || "ORDINARY CASE"
    if sam == 1
      puts medical_case_type
    end
#    select "medicalCaseType", "label=#{medical_case_type}" #label=ORDINARY CASE, INTENSIVE CASE, CATASTROPHIC CASE, SUPER CATASTROPHIC CASE
    type("memberInfo.memberPostalCode", "1600")
    type "memberInfo.membershipID", "7654327"

    type "memberInfo.memberAddress", "Selenium Testing Address"
    type "memberInfo.employerName", "Exist"
    type "memberInfo.employerAddress.address", "502"
    type "memberInfo.employerAddress.city", "Pasig"
    type "memberInfo.employerAddress.province", "Manila"
    select "memberInfo.employerAddress.country", "label=PHILIPPINES"
    type "memberInfo.employerAddress.postalCode", "1605"
    type "memberInfo.employerMembershipID", "7654321"
    sleep 2
    
    if options[:case_rate_type]
              select("id=phCaseRateType", "label=#{options[:case_rate_type]}")
              sleep 2
              click "id=btnCaseRateLookup"
              sleep 5
              if options[:case_rate_type] == "SURGICAL"
                          sleep 6
                          type "id=rvs_entity_finder_key", options[:case_rate]
                          sleep 6
                          click "css=#rvsAction > input[type=\"button\"]"
                          sleep 10
                          click "link=#{options[:case_rate]}"
                          sleep 6
              else
                          type "id=med_group_entity_finder_key", options[:group_name]
                          #type "id=med_entity_finder_key", "A91"
                          click "css=#icd10Action > input[type=\"button\"]"
                          sleep 10
                          click "link=#{options[:case_rate]}"
                          sleep 5
              end
              if options[:multiple1]
                 type "id=firstCaseSessionNo",  options[:no_of_session]
                 while options[:no_of_session] != 0
                         d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
                         my_set_date = (((d -  options[:no_of_session]) + 1).strftime("%m/%d/%Y").upcase).to_s
                         my_set_date = Date.parse my_set_date
                         d = my_set_date.strftime("%d").to_s
                         day = d.to_s
                         puts day
                         click "css=#firstCaseRateSessionDiv > div.inputGroup > img.ui-datepicker-trigger"
                         sleep 5
                         click "link=#{day}"
                         sleep 2
                         click "id=firstCaseAdd"
                         sleep 3
                         options[:no_of_session] -=1
                         is_text_present(my_set_date) 
                 end
              end
    end

    if options[:case_rate_type2]
              select "id=phCaseRateTypeSecond", "label=#{options[:case_rate_type2]}"
              sleep 2
              click "id=btnCaseRateLookupSecond"
              sleep 5
              if options[:case_rate_type2] == "SURGICAL"
                      type "id=rvs_entity_finder_key",  options[:case_rate2]
                      sleep 2
                      click "css=#rvsAction > input[type=\"button\"]"
                      sleep 2
                      click "link=#{options[:case_rate2]}"
                      sleep 2
              else
                      type "id=med_entity_finder_key", options[:case_rat2]
                      sleep 2
                      click "css=#icd10Action > input[type=\"button\"]"
                      sleep 2
                      click "link=#{options[:case_rate2]}"
                      sleep 5
              end
              if options[:multiple2]
                 type "id=secondCaseSessionNo",  options[:no_of_session2]
                 while options[:no_of_session2] != 0
                         d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
                         my_set_date = (((d -  options[:no_of_session2]) + 1).strftime("%m/%d/%Y").upcase).to_s
                         my_set_date = Date.parse my_set_date
                         d = my_set_date.strftime("%d").to_s
                         day = d.to_s
                         puts day
                         click "css=#secondCaseRateSessionDiv > div.inputGroup > img.ui-datepicker-trigger"
                         sleep 2
                         click "link=#{day}"
                         sleep 2
                         click "id=secondCaseAdd"
                         sleep 3
                         options[:no_of_session2] -=1
                         is_text_present(my_set_date)
                 end
              end
    end


    if options[:rvu_code]
#      click "btnRVULookup", :wait_for => :element, :element => "rvu_entity_finder_key"
#      type "rvu_entity_finder_key", options[:rvu_code]
#      click "//input[@value='Search']", :wait_for => :element, :element => "css=#rvu_finder_table_body>tr>td>div"
#      click "css=#rvu_finder_table_body>tr>td>div", :wait_for => :not_visible, :element => "css=#rvu_finder_table_body>tr>td>div"
#      sleep 3
    end

      if options[:surgeon_type] || options[:anesthesiologist_type]
        select "surgeon.pfClass", "label=#{options[:surgeon_type]}" if is_element_present("surgeon.pfClass")
        select "anesthesiologist.pfClass", "label=#{options[:anesthesiologist_type]}" if is_element_present("anesthesiologist.pfClass")

       # click "btnCompute", :wait_for => :page
      # click "id=btnCompute", :wait_for => :page
       # sleep 20
      end
    #tick doctor pf
    sleep 5
    if is_checked("id=1stCaseDoctor-0") == false
           click "id=1stCaseDoctor-0"
    end
    if options[:case_rate_type2]
          if is_checked("id=2ndCaseDoctor-0") == false
           click "id=2ndCaseDoctor-0"
          end
    end
    if options[:compute]
      return false if !is_editable("btnCompute")      
      #click "btnCompute"
      click "id=btnCompute"
      sleep 6
      if is_alert_present
              my_alert = get_alert # return alert for same diagnosis within 90days v1.5 02/22/2012
              puts(my_alert)
              return my_alert
      else
            wait_for_page_to_load
            sleep 20
      end
      sleep 40
      amc = (get_text Locators::Philhealth.actual_medicine_charges).gsub(",","") if is_element_present Locators::Philhealth.actual_medicine_charges
      rabac = (get_text Locators::Philhealth.room_and_board_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.room_and_board_actual_charges
      rababc = (get_text Locators::Philhealth.room_and_board_actual_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.room_and_board_actual_benefit_claim
      raac = (get_text Locators::Philhealth.rb_availed_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.rb_availed_actual_charges
      raabc = (get_text Locators::Philhealth.rb_availed_actual_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.rb_availed_actual_benefit_claim
      amb = (get_text Locators::Philhealth.actual_medicine_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.actual_medicine_benefit_claim
      alc = (get_text Locators::Philhealth.actual_lab_charges).gsub(",","") if is_element_present Locators::Philhealth.actual_lab_charges
      albc = (get_text Locators::Philhealth.actual_lab_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.actual_lab_benefit_claim
      aoc = (get_text Locators::Philhealth.actual_operation_charges).gsub(",","") if is_element_present Locators::Philhealth.actual_operation_charges
      aobc = (get_text Locators::Philhealth.actual_operation_benefit).gsub(",","") if is_element_present Locators::Philhealth.actual_operation_benefit
      tac = (get_text Locators::Philhealth.total_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.total_actual_charges
      tabc = (get_text Locators::Philhealth.total_actual_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.total_actual_benefit_claim
      mbd = (get_text Locators::Philhealth.max_benefit_drugs).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_drugs
      mbxlo = (get_text Locators::Philhealth.max_benefit_xray_lab_others).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_xray_lab_others
      mbo = (get_text Locators::Philhealth.max_benefit_operation).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_operation
      mbrb = (get_text Locators::Philhealth.max_benefit_rb).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_rb
      dfpct = (get_text Locators::Philhealth.deduction_from_previous_confinements_total).gsub(",","") if is_element_present Locators::Philhealth.deduction_from_previous_confinements_total
      dfpcapd = (get_text Locators::Philhealth.deduction_from_previous_confinements_amt_per_day).gsub(",","") if is_element_present Locators::Philhealth.deduction_from_previous_confinements_amt_per_day
      dfpcta = (get_text Locators::Philhealth.deduction_from_previous_confinements_total_amount).gsub(",","") if is_element_present Locators::Philhealth.deduction_from_previous_confinements_total_amount
      dfpcc = (get_text Locators::Philhealth.deduction_from_previous_confinements_consumed).gsub(",","") if is_element_present Locators::Philhealth.deduction_from_previous_confinements_consumed
      mbrbapd = (get_text Locators::Philhealth.max_benefit_rb_amt_per_day).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_rb_amt_per_day
      mbrbt = (get_text Locators::Philhealth.max_benefit_rb_total_amt).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_rb_total_amt
      ddc = (get_text Locators::Philhealth.deductions_drugs).gsub(",","") if is_element_present Locators::Philhealth.deductions_drugs
      drbc = (get_text Locators::Philhealth.remaining_drug_benefits).gsub(",","") if is_element_present Locators::Philhealth.remaining_drug_benefits
      ldc = (get_text Locators::Philhealth.deductions_xray_lab_others).gsub(",","") if is_element_present Locators::Philhealth.deductions_xray_lab_others

      lrbc = (get_text Locators::Philhealth.remaining_xray_lab_others_benefits).gsub(",","") if is_element_present Locators::Philhealth.remaining_xray_lab_others_benefits

      odc = (get_text Locators::Philhealth.remaining_operation_deductions).gsub(",","") if is_element_present Locators::Philhealth.remaining_operation_deductions
      drb = (get_text Locators::Philhealth.deductions_room_and_board).gsub(",","") if is_element_present Locators::Philhealth.deductions_room_and_board
      rrb = (get_text Locators::Philhealth.remaining_room_and_board).gsub(",","") if is_element_present Locators::Philhealth.remaining_room_and_board
      #rnl = (get_text Locators::Philhealth.reference_number_label).gsub(",","") if is_element_present Locators::Philhealth.reference_number_label
      aac = (get_text Locators::Philhealth.anesthesiologist_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.anesthesiologist_actual_charges
      abc = (get_text Locators::Philhealth.anesthesiologist_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.anesthesiologist_benefit_claim
      sac = (get_text Locators::Philhealth.surgeon_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.surgeon_actual_charges

      sbc = (get_text Locators::Philhealth.surgeon_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.surgeon_benefit_claim

      iapbc = (get_text Locators::Philhealth.inpatient_physician_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.inpatient_physician_benefit_claim
      isbc = (get_text Locators::Philhealth.inpatient_surgeon_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.inpatient_surgeon_benefit_claim
      iabc = (get_text Locators::Philhealth.inpatient_anesthesiologist_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.inpatient_anesthesiologist_benefit_claim

      # ER Page Info for xpaths
      er_amc = (get_text Locators::ER_Philhealth.actual_medicine_charges).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_medicine_charges
      er_alc = (get_text Locators::ER_Philhealth.actual_lab_charges).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_lab_charges
      er_aoc = (get_text Locators::ER_Philhealth.actual_operation_charges).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_operation_charges
      er_tac = (get_text Locators::ER_Philhealth.total_actual_charges).gsub(",","") if is_element_present Locators::ER_Philhealth.total_actual_charges
      er_amb = (get_text Locators::ER_Philhealth.actual_medicine_benefit_claim).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_medicine_benefit_claim
      er_albc = (get_text Locators::ER_Philhealth.actual_lab_benefit_claim).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_lab_benefit_claim
      er_aobc = (get_text Locators::ER_Philhealth.actual_operation_benefit).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_operation_benefit
      er_tabc = (get_text Locators::ER_Philhealth.total_actual_benefit_claim).gsub(",","") if is_element_present Locators::ER_Philhealth.total_actual_benefit_claim
      er_mbd = (get_text Locators::ER_Philhealth.max_benefit_drugs).gsub(",","") if is_element_present Locators::ER_Philhealth.max_benefit_drugs
      er_mbxlo = (get_text Locators::ER_Philhealth.max_benefit_xray_lab_others).gsub(",","") if is_element_present Locators::ER_Philhealth.max_benefit_xray_lab_others
      er_mbo = (get_text Locators::ER_Philhealth.max_benefit_operation).gsub(",","") if is_element_present Locators::ER_Philhealth.max_benefit_operation

      # OR Page Info for xpaths
      or_rba = (get_text Locators::OR_Philhealth.rb_availed_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.rb_availed_charges
      or_amc = (get_text Locators::OR_Philhealth.actual_medicine_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_medicine_charges
      or_alc = (get_text Locators::OR_Philhealth.actual_lab_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_lab_charges

      or_aoc = (get_text Locators::OR_Philhealth.actual_operation_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_operation_charges

      or_tac = (get_text Locators::OR_Philhealth.total_actual_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.total_actual_charges
      or_rbbc = (get_text Locators::OR_Philhealth.rb_availed_benefit_claim).gsub(",","") if is_element_present Locators::OR_Philhealth.rb_availed_benefit_claim
      or_amb = (get_text Locators::OR_Philhealth.actual_medicine_benefit_claim).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_medicine_benefit_claim
      or_albc = (get_text Locators::OR_Philhealth.actual_lab_benefit_claim).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_lab_benefit_claim
      or_aobc = (get_text Locators::OR_Philhealth.actual_operation_benefit).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_operation_benefit
      or_tabc = (get_text Locators::OR_Philhealth.total_actual_benefit_claim).gsub(",","") if is_element_present Locators::OR_Philhealth.total_actual_benefit_claim
      or_mbd = (get_text Locators::OR_Philhealth.max_benefit_drugs).gsub(",","") if is_element_present Locators::OR_Philhealth.max_benefit_drugs
      or_mbxlo = (get_text Locators::OR_Philhealth.max_benefit_xray_lab_others).gsub(",","") if is_element_present Locators::OR_Philhealth.max_benefit_xray_lab_others
      or_mbo = (get_text Locators::OR_Philhealth.max_benefit_operation).gsub(",","") if is_element_present Locators::OR_Philhealth.max_benefit_operation
      or_pf_fee  = (get_text Locators::OR_Philhealth.or_pf_physician_fee).gsub(",","") if is_element_present Locators::OR_Philhealth.or_pf_physician_fee
      return {
        :actual_medicine_charges => amc,
        :room_and_board_actual_charges => rabac,
        :room_and_board_actual_benefit_claim => rababc,
        :rb_availed_actual_charges => raac,
        :rb_availed_actual_benefit_claim => raabc,
        :actual_medicine_benefit_claim => amb,
        :actual_lab_charges => alc,
        :actual_lab_benefit_claim => albc,
        :actual_operation_charges => aoc,
        :actual_operation_benefit_claim => aobc,
        :total_actual_charges => tac,
        :total_actual_benefit_claim => tabc,
        :max_benefit_drugs => mbd,
        :max_benefit_xray_lab_others => mbxlo,
        :max_benefit_operation => mbo,
        :max_benefit_rb => mbrb,
        :deduction_from_previous_confinements_total => dfpct,
        :deduction_from_previous_confinements_amt_per_day => dfpcapd,
        :deduction_from_previous_confinements_total_amount => dfpcta,
        :deduction_from_previous_confinements_consumed => dfpcc,
        :max_benefit_rb_amt_per_day => mbrbapd,
        :max_benefit_rb_total_amt => mbrbt,
        :drugs_deduction_claims => ddc,
        :drugs_remaining_benefit_claims => drbc,
        :lab_deduction_claims => ldc,
        :lab_remaining_benefit_claims => lrbc,
        :operation_deduction_claims => odc,
        :room_and_board_deduction => drb,
        :room_and_board_remaining => rrb,
        #:reference_number_label => rnl,
        :actual_anesthesiologist_charges => aac,
        :anesthesiologist_benefit_claim => abc,
        :actual_surgeon_charges => sac,
        :surgeon_benefit_claim => sbc,
        :inpatient_surgeon_benefit_claim => isbc,
        :inpatient_anesthesiologist_benefit_claim => iabc,
        :inpatient_physician_benefit_claim => iapbc,
        :er_actual_medicine_charges => er_amc,
        :er_actual_lab_charges => er_alc,
        :er_actual_operation_charges => er_aoc,
        :er_total_actual_charges => er_tac,
        :er_actual_medicine_benefit_claim => er_amb,
        :er_actual_lab_benefit_claim => er_albc,
        :er_actual_operation_benefit_claim => er_aobc,
        :er_total_actual_benefit_claim => er_tabc,
        :er_max_benefit_drugs => er_mbd,
        :er_max_benefit_xray_lab_others => er_mbxlo,
        :er_max_benefit_operation => er_mbo,
        :or_rb_availed_charges => or_rba,
        :or_actual_medicine_charges => or_amc,
        :or_actual_lab_charges => or_alc,
        :or_actual_operation_charges => or_aoc,
        :or_total_actual_charges => or_tac,
        :or_rb_availed_benefit_claim => or_rbbc,
        :or_actual_medicine_benefit_claim => or_amb,
        :or_actual_lab_benefit_claim => or_albc,
        :or_actual_operation_benefit_claim => or_aobc,
        :or_total_actual_benefit_claim => or_tabc,
        :or_max_benefit_drugs => or_mbd,
        :or_max_benefit_xray_lab_others => or_mbxlo,
        :or_max_benefit_operation => or_mbo,
        :or_physician_fee => or_pf_fee,
       }
    end
  end
  def my_philhealth_computation(options ={})
    if options[:rvu_code] !=nil
              options[:case_rate_type] = "SURGICAL"
              options[:case_rate] = options[:rvu_code]
    end
    if options[:medical_case_type]
               options[:case_rate_type] = "MEDICAL"
               options[:group_name] = options[:diagnosis]
               options[:case_rate] = options[:diagnosis] + ".1"
               puts options[:case_rate] 
    end

    if options[:special_unit]
            options[:case_rate_type] = false
    end
    diagnosis = options[:diagnosis] || "GLAUCOMA"
    sleep 2
    is_text_present "PhilHealth Reference No.:"
    if options[:edit]
      click "btnEdit"
      click "id=btnClear"
      sleep 5
    end
    select "claimType", "label=#{options[:claim_type]}" if options[:claim_type] if is_visible "claimType"
    click "btnDiagnosisLookup", :wait_for => :element, :element => "icd10_entity_finder_key"
    type "icd10_entity_finder_key", diagnosis
    click "//input[@value='Search' and @type='button' and @onclick='Icd10Finder.search();']", :wait_for => :element, :element => "link=#{diagnosis}"
    click "link=#{diagnosis}", :wait_for => :not_visible, :element => "link=#{diagnosis}"
    sam = "med_case_type N/A"
    medical_case_type = options[:medical_case_type] || "ORDINARY CASE"
    if sam == 1
      puts medical_case_type
    end
#    select "medicalCaseType", "label=#{medical_case_type}" #label=ORDINARY CASE, INTENSIVE CASE, CATASTROPHIC CASE, SUPER CATASTROPHIC CASE
    type("memberInfo.memberPostalCode", "1600")
    type "memberInfo.membershipID", "7654327"
    type "memberInfo.memberAddress", "Selenium Testing Address"
    type "memberInfo.employerName", "Exist"
    type "memberInfo.employerAddress.address", "502"
    type "memberInfo.employerAddress.city", "Pasig"
    type "memberInfo.employerAddress.province", "Manila"
    select "memberInfo.employerAddress.country", "label=PHILIPPINES"
    type "memberInfo.employerAddress.postalCode", "1605"
    type "memberInfo.employerMembershipID", "7654321"
    sleep 2

    if options[:case_rate_type]
              select("id=phCaseRateType", "label=#{options[:case_rate_type]}")
              sleep 2
              click "id=btnCaseRateLookup"
              sleep 5
              if options[:case_rate_type] == "SURGICAL"
                          sleep 3
                          type "id=rvs_entity_finder_key", options[:case_rate]
                          sleep 3
                          click "css=#rvsAction > input[type=\"button\"]"
                          sleep 6
                          click "link=#{options[:case_rate]}"
                          sleep 6
              else

                          type "id=med_group_entity_finder_key", options[:group_name]
                          #type "id=med_entity_finder_key", "A91"
                          click "css=#icd10Action > input[type=\"button\"]"
                          sleep 5
                          click "link=#{options[:case_rate]}"
                          sleep 5
              end
    end

    if options[:case_rate_type2]
              select "id=phCaseRateTypeSecond", "label=#{options[:case_rate_type2]}"
              sleep 2
              click "id=btnCaseRateLookupSecond"
              sleep 5
              if options[:case_rate_type2] == "SURGICAL"
                      type "id=rvs_entity_finder_key",  options[:case_rate2]
                      sleep 2
                      click "css=#rvsAction > input[type=\"button\"]"
                      sleep2
                      click "link=#{options[:case_rate2]}"
                      sleep 2
              else
                      type "id=med_entity_finder_key", options[:case_rat2]
                      sleep 2
                      click "css=#icd10Action > input[type=\"button\"]"
                      sleep 2
                      click "link=#{options[:case_rate2]}"
                      sleep 5
              end
    end


    if options[:rvu_code]
#      click "btnRVULookup", :wait_for => :element, :element => "rvu_entity_finder_key"
#      type "rvu_entity_finder_key", options[:rvu_code]
#      click "//input[@value='Search']", :wait_for => :element, :element => "css=#rvu_finder_table_body>tr>td>div"
#      click "css=#rvu_finder_table_body>tr>td>div", :wait_for => :not_visible, :element => "css=#rvu_finder_table_body>tr>td>div"
#      sleep 3
    end

      if options[:surgeon_type] || options[:anesthesiologist_type]
        select "surgeon.pfClass", "label=#{options[:surgeon_type]}" if is_element_present("surgeon.pfClass")
        select "anesthesiologist.pfClass", "label=#{options[:anesthesiologist_type]}" if is_element_present("anesthesiologist.pfClass")

       # click "btnCompute", :wait_for => :page
      # click "id=btnCompute", :wait_for => :page
       # sleep 20
      end
    #tick doctor pf
    sleep 5
    if is_checked("id=1stCaseDoctor-0") == false
           click "id=1stCaseDoctor-0"
    end
    if options[:compute]
      return false if !is_editable("btnCompute")
      #click "btnCompute"
      click "id=btnCompute"
      sleep 6
      if is_alert_present
              my_alert = get_alert # return alert for same diagnosis within 90days v1.5 02/22/2012
              puts(my_alert)
              return my_alert
      else
            wait_for_page_to_load
            sleep 20
      end
      sleep 10
      amc = (get_text Locators::Philhealth.actual_medicine_charges).gsub(",","") if is_element_present Locators::Philhealth.actual_medicine_charges
      rabac = (get_text Locators::Philhealth.room_and_board_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.room_and_board_actual_charges
      rababc = (get_text Locators::Philhealth.room_and_board_actual_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.room_and_board_actual_benefit_claim
      raac = (get_text Locators::Philhealth.rb_availed_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.rb_availed_actual_charges
      raabc = (get_text Locators::Philhealth.rb_availed_actual_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.rb_availed_actual_benefit_claim
      amb = (get_text Locators::Philhealth.actual_medicine_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.actual_medicine_benefit_claim
      alc = (get_text Locators::Philhealth.actual_lab_charges).gsub(",","") if is_element_present Locators::Philhealth.actual_lab_charges
      albc = (get_text Locators::Philhealth.actual_lab_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.actual_lab_benefit_claim
      aoc = (get_text Locators::Philhealth.actual_operation_charges).gsub(",","") if is_element_present Locators::Philhealth.actual_operation_charges
      aobc = (get_text Locators::Philhealth.actual_operation_benefit).gsub(",","") if is_element_present Locators::Philhealth.actual_operation_benefit
      tac = (get_text Locators::Philhealth.total_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.total_actual_charges
      tabc = (get_text Locators::Philhealth.total_actual_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.total_actual_benefit_claim
      mbd = (get_text Locators::Philhealth.max_benefit_drugs).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_drugs
      mbxlo = (get_text Locators::Philhealth.max_benefit_xray_lab_others).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_xray_lab_others
      mbo = (get_text Locators::Philhealth.max_benefit_operation).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_operation
      mbrb = (get_text Locators::Philhealth.max_benefit_rb).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_rb
      dfpct = (get_text Locators::Philhealth.deduction_from_previous_confinements_total).gsub(",","") if is_element_present Locators::Philhealth.deduction_from_previous_confinements_total
      dfpcapd = (get_text Locators::Philhealth.deduction_from_previous_confinements_amt_per_day).gsub(",","") if is_element_present Locators::Philhealth.deduction_from_previous_confinements_amt_per_day
      dfpcta = (get_text Locators::Philhealth.deduction_from_previous_confinements_total_amount).gsub(",","") if is_element_present Locators::Philhealth.deduction_from_previous_confinements_total_amount
      dfpcc = (get_text Locators::Philhealth.deduction_from_previous_confinements_consumed).gsub(",","") if is_element_present Locators::Philhealth.deduction_from_previous_confinements_consumed
      mbrbapd = (get_text Locators::Philhealth.max_benefit_rb_amt_per_day).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_rb_amt_per_day
      mbrbt = (get_text Locators::Philhealth.max_benefit_rb_total_amt).gsub(",","") if is_element_present Locators::Philhealth.max_benefit_rb_total_amt
      ddc = (get_text Locators::Philhealth.deductions_drugs).gsub(",","") if is_element_present Locators::Philhealth.deductions_drugs
      drbc = (get_text Locators::Philhealth.remaining_drug_benefits).gsub(",","") if is_element_present Locators::Philhealth.remaining_drug_benefits
      ldc = (get_text Locators::Philhealth.deductions_xray_lab_others).gsub(",","") if is_element_present Locators::Philhealth.deductions_xray_lab_others

      lrbc = (get_text Locators::Philhealth.remaining_xray_lab_others_benefits).gsub(",","") if is_element_present Locators::Philhealth.remaining_xray_lab_others_benefits

      odc = (get_text Locators::Philhealth.remaining_operation_deductions).gsub(",","") if is_element_present Locators::Philhealth.remaining_operation_deductions
      drb = (get_text Locators::Philhealth.deductions_room_and_board).gsub(",","") if is_element_present Locators::Philhealth.deductions_room_and_board
      rrb = (get_text Locators::Philhealth.remaining_room_and_board).gsub(",","") if is_element_present Locators::Philhealth.remaining_room_and_board
      #rnl = (get_text Locators::Philhealth.reference_number_label).gsub(",","") if is_element_present Locators::Philhealth.reference_number_label
      aac = (get_text Locators::Philhealth.anesthesiologist_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.anesthesiologist_actual_charges
      abc = (get_text Locators::Philhealth.anesthesiologist_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.anesthesiologist_benefit_claim
      sac = (get_text Locators::Philhealth.surgeon_actual_charges).gsub(",","") if is_element_present Locators::Philhealth.surgeon_actual_charges

      sbc = (get_text Locators::Philhealth.surgeon_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.surgeon_benefit_claim

      iapbc = (get_text Locators::Philhealth.inpatient_physician_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.inpatient_physician_benefit_claim
      isbc = (get_text Locators::Philhealth.inpatient_surgeon_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.inpatient_surgeon_benefit_claim
      iabc = (get_text Locators::Philhealth.inpatient_anesthesiologist_benefit_claim).gsub(",","") if is_element_present Locators::Philhealth.inpatient_anesthesiologist_benefit_claim

      # ER Page Info for xpaths
      er_amc = (get_text Locators::ER_Philhealth.actual_medicine_charges).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_medicine_charges
      er_alc = (get_text Locators::ER_Philhealth.actual_lab_charges).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_lab_charges
      er_aoc = (get_text Locators::ER_Philhealth.actual_operation_charges).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_operation_charges
      er_tac = (get_text Locators::ER_Philhealth.total_actual_charges).gsub(",","") if is_element_present Locators::ER_Philhealth.total_actual_charges
      er_amb = (get_text Locators::ER_Philhealth.actual_medicine_benefit_claim).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_medicine_benefit_claim
      er_albc = (get_text Locators::ER_Philhealth.actual_lab_benefit_claim).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_lab_benefit_claim
      er_aobc = (get_text Locators::ER_Philhealth.actual_operation_benefit).gsub(",","") if is_element_present Locators::ER_Philhealth.actual_operation_benefit
      er_tabc = (get_text Locators::ER_Philhealth.total_actual_benefit_claim).gsub(",","") if is_element_present Locators::ER_Philhealth.total_actual_benefit_claim
      er_mbd = (get_text Locators::ER_Philhealth.max_benefit_drugs).gsub(",","") if is_element_present Locators::ER_Philhealth.max_benefit_drugs
      er_mbxlo = (get_text Locators::ER_Philhealth.max_benefit_xray_lab_others).gsub(",","") if is_element_present Locators::ER_Philhealth.max_benefit_xray_lab_others
      er_mbo = (get_text Locators::ER_Philhealth.max_benefit_operation).gsub(",","") if is_element_present Locators::ER_Philhealth.max_benefit_operation

      # OR Page Info for xpaths
      or_rba = (get_text Locators::OR_Philhealth.rb_availed_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.rb_availed_charges
      or_amc = (get_text Locators::OR_Philhealth.actual_medicine_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_medicine_charges
      or_alc = (get_text Locators::OR_Philhealth.actual_lab_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_lab_charges

      or_aoc = (get_text Locators::OR_Philhealth.actual_operation_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_operation_charges

      or_tac = (get_text Locators::OR_Philhealth.total_actual_charges).gsub(",","") if is_element_present Locators::OR_Philhealth.total_actual_charges
      or_rbbc = (get_text Locators::OR_Philhealth.rb_availed_benefit_claim).gsub(",","") if is_element_present Locators::OR_Philhealth.rb_availed_benefit_claim
      or_amb = (get_text Locators::OR_Philhealth.actual_medicine_benefit_claim).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_medicine_benefit_claim
      or_albc = (get_text Locators::OR_Philhealth.actual_lab_benefit_claim).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_lab_benefit_claim
      or_aobc = (get_text Locators::OR_Philhealth.actual_operation_benefit).gsub(",","") if is_element_present Locators::OR_Philhealth.actual_operation_benefit
      or_tabc = (get_text Locators::OR_Philhealth.total_actual_benefit_claim).gsub(",","") if is_element_present Locators::OR_Philhealth.total_actual_benefit_claim
      or_mbd = (get_text Locators::OR_Philhealth.max_benefit_drugs).gsub(",","") if is_element_present Locators::OR_Philhealth.max_benefit_drugs
      or_mbxlo = (get_text Locators::OR_Philhealth.max_benefit_xray_lab_others).gsub(",","") if is_element_present Locators::OR_Philhealth.max_benefit_xray_lab_others
      or_mbo = (get_text Locators::OR_Philhealth.max_benefit_operation).gsub(",","") if is_element_present Locators::OR_Philhealth.max_benefit_operation
      return {
        :actual_medicine_charges => amc,
        :room_and_board_actual_charges => rabac,
        :room_and_board_actual_benefit_claim => rababc,
        :rb_availed_actual_charges => raac,
        :rb_availed_actual_benefit_claim => raabc,
        :actual_medicine_benefit_claim => amb,
        :actual_lab_charges => alc,
        :actual_lab_benefit_claim => albc,
        :actual_operation_charges => aoc,
        :actual_operation_benefit_claim => aobc,
        :total_actual_charges => tac,
        :total_actual_benefit_claim => tabc,
        :max_benefit_drugs => mbd,
        :max_benefit_xray_lab_others => mbxlo,
        :max_benefit_operation => mbo,
        :max_benefit_rb => mbrb,
        :deduction_from_previous_confinements_total => dfpct,
        :deduction_from_previous_confinements_amt_per_day => dfpcapd,
        :deduction_from_previous_confinements_total_amount => dfpcta,
        :deduction_from_previous_confinements_consumed => dfpcc,
        :max_benefit_rb_amt_per_day => mbrbapd,
        :max_benefit_rb_total_amt => mbrbt,
        :drugs_deduction_claims => ddc,
        :drugs_remaining_benefit_claims => drbc,
        :lab_deduction_claims => ldc,
        :lab_remaining_benefit_claims => lrbc,
        :operation_deduction_claims => odc,
        :room_and_board_deduction => drb,
        :room_and_board_remaining => rrb,
        #:reference_number_label => rnl,
        :actual_anesthesiologist_charges => aac,
        :anesthesiologist_benefit_claim => abc,
        :actual_surgeon_charges => sac,
        :surgeon_benefit_claim => sbc,
        :inpatient_surgeon_benefit_claim => isbc,
        :inpatient_anesthesiologist_benefit_claim => iabc,
        :inpatient_physician_benefit_claim => iapbc,
        :er_actual_medicine_charges => er_amc,
        :er_actual_lab_charges => er_alc,
        :er_actual_operation_charges => er_aoc,
        :er_total_actual_charges => er_tac,
        :er_actual_medicine_benefit_claim => er_amb,
        :er_actual_lab_benefit_claim => er_albc,
        :er_actual_operation_benefit_claim => er_aobc,
        :er_total_actual_benefit_claim => er_tabc,
        :er_max_benefit_drugs => er_mbd,
        :er_max_benefit_xray_lab_others => er_mbxlo,
        :er_max_benefit_operation => er_mbo,
        :or_rb_availed_charges => or_rba,
        :or_actual_medicine_charges => or_amc,
        :or_actual_lab_charges => or_alc,
        :or_actual_operation_charges => or_aoc,
        :or_total_actual_charges => or_tac,
        :or_rb_availed_benefit_claim => or_rbbc,
        :or_actual_medicine_benefit_claim => or_amb,
        :or_actual_lab_benefit_claim => or_albc,
        :or_actual_operation_benefit_claim => or_aobc,
        :or_total_actual_benefit_claim => or_tabc,
        :or_max_benefit_drugs => or_mbd,
        :or_max_benefit_xray_lab_others => or_mbxlo,
        :or_max_benefit_operation => or_mbo,
       }
    end
  end
  def ph_compute_witout_data_population
#    click "btnCompute", :wait_for => :page
    click "id=btnCompute", :wait_for => :page

    is_text_present("For less than 24 hours confinement and without operation, only \"Refund\" claim type is accepted.\nMember ID is a required field.\nEmployer Name is a required field.\nEmployer Number and Street is a required field.\nICD10 is required when saving PhilHealth form.")
  end
  def get_total_claims_history(page)
    if page == "oss" ## DAS OSS Page
      rows = get_xpath_count("//html/body/div/div[2]/div[2]/form/div[7]/div/div[15]/div[2]/table/tbody/tr/td[5]").to_i
      # medicine total claim history
      med_total = 0.0
      rows.times do |row|
        med_total += get_text("//html/body/div/div[2]/div[2]/form/div[7]/div/div[15]/div[2]/table/tbody/tr[#{row + 1}]/td[8]").gsub(',','').to_f

      end
      # laboratory total claim history
      lab_total = 0.0
      rows.times do |row|
        lab_total += get_text("//html/body/div/div[2]/div[2]/form/div[7]/div/div[15]/div[2]/table/tbody/tr[#{row + 1}]/td[9]").gsub(',','').to_f
      end
      # operation total claim history
      operation_total = 0.0
      rows.times do |row|
        operation_total += get_text("//html/body/div/div[2]/div[2]/form/div[7]/div/div[15]/div[2]/table/tbody/tr[#{row + 1}]/td[10]").gsub(',','').to_f
      end
      # total claim history
      total = 0.0
      rows.times do |row|
        total += get_text("//html/body/div/div[2]/div[2]/form/div[7]/div/div[15]/div[2]/table/tbody/tr[#{row + 1}]/td[11]").gsub(',','').to_f
      end
    else ## Philhealth Outpatient Page
      rows = get_xpath_count("//html/body/div/div[2]/div[2]/form/div[4]/div[10]/div[2]/table/tbody/tr/td[8]").to_i
      # medicine total claim history
      med_total = 0.0
      rows.times do |row|
        med_total += get_text("//html/body/div/div[2]/div[2]/form/div[4]/div[10]/div[2]/table/tbody/tr[#{row + 1}]/td[8]").gsub(',','').to_f
      end
      # laboratory total claim history
      lab_total = 0.0
      rows.times do |row|
        lab_total += get_text("//html/body/div/div[2]/div[2]/form/div[4]/div[10]/div[2]/table/tbody/tr[#{row + 1}]/td[9]").gsub(',','').to_f
      end
      # operation total claim history
      operation_total = 0.0
      rows.times do |row|
        operation_total += get_text("//html/body/div/div[2]/div[2]/form/div[4]/div[10]/div[2]/table/tbody/tr[#{row + 1}]/td[10]").gsub(',','').to_f
      end
      # total claim history
      total = 0.0
      rows.times do |row|
        total += get_text("//html/body/div/div[2]/div[2]/form/div[4]/div[10]/div[2]/table/tbody/tr[#{row + 1}]/td[11]").gsub(',','').to_f
      end
    end
    return {
      :total_med_claims => med_total,
      :total_lab_claims => lab_total,
      :total_operation_claims => operation_total,
      :total_claims => total
    }
  end
  # save the ph computation
   def ph_save_computation_alert#(options ={})
   sleep 20
    return false if !is_editable("btnSave")
    click "btnSave" # :wait_for => :page
    sleep 10
     # if is_confirmation_present
         get_confirmation() =~ /^Please click the Compute button to apply the computation of Philhealth claim./
        #if is_alert_present
              choose_ok_on_next_confirmation()
          #    ("Please click the Compute button to apply the computation of Philhealth claim.").should == page.get_alert
              sleep 3
              click "id=btnCompute"
              sleep 10
              click "id=btnSave"
           #   sleep 10
           puts "recompute done"
      #end
    sleep 30
   ref_num = get_text Locators::Philhealth.reference_number_label1 if is_element_present(Locators::Philhealth.reference_number_label1)
   puts "reference_number_label1 - #{ref_num}"
    ref_num = get_text Locators::Philhealth.reference_number_label2 if is_element_present(Locators::Philhealth.reference_number_label2)
       puts "reference_number_label2 - #{ref_num}"
    ref_num = get_text Locators::Philhealth.reference_number_label3 if is_element_present(Locators::Philhealth.reference_number_label3)
sleep 3
    puts "reference_number_label2 - #{ref_num}"
    if ref_num.include?("PhilHealth Reference No")
      return ref_num.gsub("PhilHealth Reference No.: ", "")
    else
      return ref_num
    end
  end
  def ph_save_computation#(options ={})
    return false if !is_editable("btnSave")
    click "btnSave" # :wait_for => :page
    sleep 10
      if is_confirmation_present  || is_alert_present
             # get_confirmation() =~ /^Please click the Compute button to apply the computation of Philhealth claim./
              get_alert() =~ /^Please click the Compute button to apply the computation of Philhealth claim./
              sleep 3
              choose_ok_on_next_confirmation()
          #    ("Please click the Compute button to apply the computation of Philhealth claim.").should == page.get_alert
              sleep 3
              click "id=btnCompute"
              sleep 10
              click "id=btnSave"
           #   sleep 10
           puts "recompute done"
      end
      if is_alert_present
             # get_confirmation() =~ /^Please click the Compute button to apply the computation of Philhealth claim./
              get_alert() =~ /^Please recompute Philhealth to capture correct total benefit claim../
              sleep 3
              choose_ok_on_next_confirmation()
          #    ("Please click the Compute button to apply the computation of Philhealth claim.").should == page.get_alert
              sleep 3
              click "id=btnCompute"
              sleep 10
              click "id=btnSave"
           #   sleep 10
           puts "recompute done"
      end      
    sleep 40
   ref_num = get_text Locators::Philhealth.reference_number_label1 if is_element_present(Locators::Philhealth.reference_number_label1)
   puts "reference_number_label1 - #{ref_num}"
    ref_num2 = get_text Locators::Philhealth.reference_number_label2 if is_element_present(Locators::Philhealth.reference_number_label2)
       puts "reference_number_label2 - #{ref_num2}"
    ref_num3 = get_text Locators::Philhealth.reference_number_label3 if is_element_present(Locators::Philhealth.reference_number_label3)
sleep 3
    puts "reference_number_label2 - #{ref_num3}"    
    if ref_num.include?("PhilHealth Reference No.:")
      return ref_num.gsub("PhilHealth Reference No.:", "")
    elsif ref_num2.include?("PhilHealth Reference No.:")
       ref_num = ref_num2.gsub("PhilHealth Reference No.:", "")
    elsif  ref_num3.include?("PhilHealth Reference No.:")
       ref_num = ref_num3.gsub("PhilHealth Reference No.:", "")
      return ref_num
    else
       return ref_num
    end
  end
  def my_ph_save_computation#(options ={})
    return false if !is_editable("btnSave")
    click "btnSave", :wait_for => :page
    sleep 15

    get_text("//a[contains(text(), 'Edit')]")
   ref_num = get_text Locators::Philhealth.reference_number_label1 if is_element_present(Locators::Philhealth.reference_number_label1)
   puts "reference_number_label1 - #{ref_num}"
    ref_num = get_text Locators::Philhealth.reference_number_label2 if is_element_present(Locators::Philhealth.reference_number_label2)
       puts "reference_number_label2 - #{ref_num}"
    ref_num = get_text Locators::Philhealth.reference_number_label3 if is_element_present(Locators::Philhealth.reference_number_label3)

    puts "reference_number_label2 - #{ref_num}"
    if ref_num.include?('PhilHealth Reference No.:')
      return ref_num.gsub("PhilHealth Reference No.: ", "")
    else
      return ref_num
    end
  end
  def ph_cancel_computation(options ={})
    return false if !is_visible("btnCancel")
    click "btnCancel", :wait_for => :element, :element => "//input[@name='btnOK' and @value='OK' and @type='button' and @onclick='saveCancelForm();']"
    type "reasonText", options[:reason] || "my reason"
    choose_ok_on_next_confirmation
    click "//input[@name='btnOK' and @value='OK' and @type='button' and @onclick='saveCancelForm();']" if is_element_present("//input[@name='btnOK' and @value='OK' and @type='button' and @onclick='saveCancelForm();']")
    get_confirmation()
    sleep 25
    is_text_present("CANCELLED")
  end
  def myrecompute()
       click "btnSave" # :wait_for => :page
        sleep 6

              get_alert() =~ /^Please click the Compute button to apply the computation of Philhealth claim./
              choose_ok_on_next_confirmation()
          #    ("Please click the Compute button to apply the computation of Philhealth claim.").should == page.get_alert
              sleep 3
              click "id=btnCompute"
              sleep 10
              click "id=btnSave"
           #   sleep 10
           puts "recompute done"

    sleep 30
   ref_num = get_text Locators::Philhealth.reference_number_label1 if is_element_present(Locators::Philhealth.reference_number_label1)
   puts "reference_number_label1 - #{ref_num}"
    ref_num = get_text Locators::Philhealth.reference_number_label2 if is_element_present(Locators::Philhealth.reference_number_label2)
       puts "reference_number_label2 - #{ref_num}"
    ref_num = get_text Locators::Philhealth.reference_number_label3 if is_element_present(Locators::Philhealth.reference_number_label3)
sleep 3
    puts "reference_number_label2 - #{ref_num}"
    if ref_num.include?("PhilHealth Reference No")
      return ref_num.gsub("PhilHealth Reference No.: ", "")
    else
      return ref_num
    end
  end

  def ph_recompute
    sleep 5
    click "btnRecompute", :wait_for => :page
    is_text_present("Complete Final Diagnosis")
  end
  def ph_print_report # AR(ESTIMATE) = NO POPUP
    if is_editable("btnPrint")
      click "btnPrint", :wait_for => :page
      get_text("errorMessages") if is_element_present("errorMessages")
      if is_visible("procedureNameTxt")
        type("procedureNameTxt", "sample procedure name")
        click("//input[@type='button' and @onclick='print();' and @value='OK' and @name='btnOK']")
      end
      sleep 20
      return true if is_text_present("PhilHealth Reference No.:")
    else
      click "btnSave", :wait_for => :page
      return false
    end
  end
  def ph_view_details(options={})
    click "btnViewDetails", :wait_for => :element, :element => "orderItemsFound"
    sleep 4
    count = get_text("orderItemsFound").to_i
    click "btnCloseDetail" if options[:close]
    sleep 2
    return count
  end
  def ph_verify_order_details
    ### will work on count all displayed details and do computations

    # quantity
    quantity = get_text("//html/body/div/div[2]/div[2]/div[11]/div[3]/table/tbody/tr/td[4]/div").to_f
    # unit price
    unit_price = get_text("//html/body/div/div[2]/div[2]/div[11]/div[3]/table/tbody/tr/td[5]/div").to_f
    # actual charges
    actual_charges = get_text("//html/body/div/div[2]/div[2]/div[11]/div[3]/table/tbody/tr/td[6]/div").to_f
    actual_charges == quantity * unit_price

    # compensable amount
    if get_text("//html/body/div/div[2]/div[2]/div[11]/div[3]/table/tbody/tr/td[7]/div") == "NON - COMPENSABLE - SUPPLIES"
      return 0
    else
      is_text_present("COMPENSABLE - SUPPLIES")
      return actual_charges
    end
   click "btnCloseDetail"
  end
  def ph_edit(options ={})
    click("id=btnEdit")

    if options[:diagnosis]
      click "btnDiagnosisLookup", :wait_for => "icd10_entity_finder_key"
      diagnosis = options[:diagnosis]
      type "icd10_entity_finder_key", diagnosis
      click "//input[@value='Search' and @type='button' and @onclick='Icd10Finder.search();']", :wait_for => :element, :element => "link=#{diagnosis}"
      click "link=#{diagnosis}"
    end
    sleep 5
  end
  def ph_clear
    click("id=btnClear")#, :wait_for => :page)
    sleep 5
  end
  def ph_go_to_mainpage
    click "btnMainPage", :wait_for => :page
    is_text_present("Patient Billing and Accounting Home")
  end
  def cancel_room_and_board_charges
    click "//input[@type='checkbox']"
    type(Locators::AdditionalRoomAndBoardCancellation.cancel_reason_text_field_first_row, "test in cancelling") if is_element_present(Locators::AdditionalRoomAndBoardCancellation.cancel_reason_text_field_first_row)
    type(Locators::AdditionalRoomAndBoardCancellation.cancel_reason_text_field_second_row, "test in cancelling") if is_element_present(Locators::AdditionalRoomAndBoardCancellation.cancel_reason_text_field_second_row)
    click "submitButton", :wait_for => :page
    is_text_present("Successfully generated Room/Board Adjustments.")
  end
  def skip_update_patient_information
        sleep 10
        puts "sss"
        click "formAction", :wait_for => :page
        puts "sss2"
        sleep 10
        # wait_for_text_present("Additional Room and Board Cancellation]")
        is_text_present("Patient Billing and Accounting Home")

  end
  # # Description: Skip cancellation of room and board charges
  def skip_room_and_bed_cancelation
    sleep 40
  #  click"name=formAction"
    #sleep 6
    if is_element_present("skipButton")
          puts "skipButton"
        click "skipButton"
    elsif is_element_present("name=formAction")
            puts "name=formAction"
           click"name=formAction"
    elsif is_element_present("name=skipButton")
            puts "name=skipButton"
             click("name=skipButton");
    elsif  is_element_present("id=btnSkip")
            puts "id=btnSkip"
            click("id=btnSkip");
    elsif is_element_present("css=a:contains('Skip)")
            click("css=a:contains('Skip)")
    else
            click("css=#Skip")
    end
#    sleep 20
#     if  is_element_present("name=skipButton")
#      click("name=skipButton");
#    end
##
##    if is_element_present("name=formAction")
##      click"name=formAction"
##    end

#
#     if is_element_present("skipButton")
#          puts "skipButton"
#        click "skipButton"
#    end

##
##     if  is_element_present("name=skipButton")
##      click("name=skipButton");
##    end
    
#     if  is_element_present("id=btnSkip")
#      click("id=btnSkip");
#    end
     sleep 40
    #wait_for_element("//html/body/div/div[2]/div[2]/div/div/ul/li[2]")
   if  is_text_present("PhilHealth Reference No.:")
         return true
   end


  end
  def skip_philhealth

    click "//input[@id='btnSkip' and @value='Skip']", :wait_for => :page

    is_text_present("Discount Information")

  end
  def skip_discount
    skip_button = is_element_present( '//input[@id="skipBtn" and @value="Skip"]') ?  '//input[@id="skipBtn" and @value="Skip"]' :  '//input[@type="submit" and @value="Skip"]'
    click skip_button, :wait_for => :page

    is_text_present("Generation of Statement of Account")

  end
  def skip_generation_of_soa
    click "//input[@value='Skip']" if is_element_present("//input[@value='Skip']")
    sleep 6
    click "name=submitButton" if is_element_present("name=submitButton")
    sleep 6

    get_text('//*[@id="paymentDataEntryHeaderDiv"]') == "Payment Data Entry"
    sleep 6

  end
  def set_patient_to_express_discharge
    click "//input[@value='Submit']", :wait_for => :page
    is_text_present("Update Patient Information")
  end
  def das_discharge(options ={})
    patient_pin_search options
    go_to_page_using_visit_number("Discharge Patient", visit_number)
    click "dischargeType2" # das
    click "//input[@name='_submit']",:wait_for => :page
    return get_text("errorMessages") if is_element_present("errorMessages")
    #    # do an if statement here to validate if the patient is allowed to go through das discharge, and all bills are settled.
    if (is_text_present("Cannot discharge due to hospital bills. Please settle amount or specify correct guarantor coverage")) || is_element_present("errorMessages")
      go_to_patient_billing_accounting_page
      patient_pin_search options
      go_to_page_using_visit_number("Update Patient Information", visit_number)
      click "guarantorId"
      click "updateLink", :wait_for => :page
      click "//input[@value='Submit']", :wait_for => :page # click submit button update guarantor page
      sleep 1
      # do an if statement here to check is LOA number, max amount and percentage limit is/are required field
      if(is_text_present ("LOA Number is a required field."))
        if(is_text_present ("Either maximum amount or percentage limit of LOA can have values but not both."))
          sleep 1
          type "//div[2]/div[2]/div[2]/input", "1234567999"
          type "//div[7]/div[2]/input", "100"
          click "_submit", :wait_for => :page
          click "//input[@value='Submit Changes']", :wait_for => :page
          go_to_patient_billing_accounting_page
          patient_pin_search options
          go_to_page_using_visit_number("Discharge Patient", visit_number)
          click "dischargeType2" # das
          click "//input[@name='_submit']",:wait_for => :page
        end
      end
      go_to_patient_billing_accounting_page
      patient_pin_search options
      go_to_page_using_visit_number("Discharge Patient", visit_number)
      update_patient_or_guarantor_info
      click "dischargeType2" # das
      click "//input[@name='_submit']",:wait_for => :page
      sleep 1
    end
  end
  def pba_get_select_options(vn)
    get_select_options("userAction#{vn}")
  end
  def pba_document_search(options={})
    click "link=View and Reprinting"
    sleep 2
    click "link=#{options[:select]}", :wait_for => :page
    sleep 10
    aaa = get_selected_label("id=searchOptions")
    puts "aaa - #{aaa}"

    if options[:search_option] == "GATE PASS"

      type "criteria", options[:entry] if options[:entry]
      click "//input[@name='search' and @value='Search']", :wait_for => :page
      return is_text_present("List of Patient with Printed Gatepass")
    elsif options[:search_option] == "DOCUMENT DATE"
      select_button = (is_element_present"searchOptions") ? "searchOptions" :  "id=searchOptions"
      select select_button, "label=#{options[:search_option]}"
      type "dateSearchEntry", options[:entry] if options[:entry]
    else
      select_button = (is_element_present"//select[@id='documentType']") ? "//select[@id='documentType']" :  "documentTypes"
      select select_button, "label=#{options[:doc_type]}" if options[:doc_type]
      
      if get_selected_label("id=searchOptions") ==  "PIN"
          select "id=searchOptions", "label=VISIT NUMBER"
      else 
        if get_selected_label("id=searchOptions") == options[:search_option]
          select "id=searchOptions", "label=PIN"
        end
       end
       
      
      select "id=searchOptions", "label=#{options[:search_options]}" if options[:search_options] && is_element_present("id=searchOptions")
#      select "id=searchOption", "label=#{options[:search_option]}" if options[:search_option] && is_element_present("id=searchOption")
  #     select "id=searchOptions", "label=#{options[:search_option]}" if options[:search_option] && is_element_present("id=searchOptions")
  #    select "id=searchOption", "label=#{options[:search_options]}" if options[:search_options] && is_element_present("id=searchOption")
	if options[:cashier_location]
			cashier_location = options[:cashier_location]
	          select "id=cashierLocations", "label=#{cashier_location}"
			#page.select "id=cashierLocations", "label=MA - Main Billing, ER Billing, Wellness" 
			#page.select "id=cashierLocations", "label=DA - Ancillary, SS"
			#page.select "id=cashierLocations", "label=CS - CSS"
			#page.select "id=cashierLocations", "label=PH - Pharmacy"
	else
			select "id=cashierLocations", "label=MA - Main Billing, ER Billing, Wellness" 		
	end

      type "id=textSearchEntry", options[:entry] if options[:entry] && (is_element_present("id=textSearchEntry"))
      sleep 5
    end
    click "id=actionButton" #:wait_for => :page
    sleep 10
    if options[:view_and_reprinting]
      return get_text('css=#orTableBody>tr.even>td:nth-child(7)>div>a').include? "Re-print OR" if options[:doc_type] == "OFFICIAL RECEIPT"
      return get_text("css=#philhealthTableBody>tr").include? "Reprint PhilHealth Form" if options[:select] == "PhilHealth"
      return get_text('css=#philhealthTableBody>tr.even>td:nth-child(8)').include? "Reprint PhilHealth Form" if options[:doc_type] == "PHILHEALTH MULTIPLE SESSION"
    else
    #  return get_text("css=#processedDiscountsBody>tr").include? "Reprint Prooflist" if options[:select] == "Discount"
      return get_text('//*[@id="processedDiscountsBody"]').include? "Reprint Prooflist" if options[:select] == "Discount"
      return get_text("css=#philhealthTableBody>tr").include? "Reprint PhilHealth Form" if options[:select] == "PhilHealth"
      return get_text('css=table[id="orSearchResults"]').include? "Re-print OR" if options[:doc_type] == "OFFICIAL RECEIPT"
      return get_text('css=table[id="orSearchResults"]').include? "Reprint Prooflist" if options[:doc_type] == "DISCOUNT"
    end
  end
  def pba_reprint_or
    sleep 20
    answer_on_next_prompt("Test Reason Sample")
    click "link=Re-print OR"#, :wait_for => :element, :element => "popup_ok" # not all reprint or has pop up
    sleep 20
    click("popup_ok") if is_element_present("popup_ok")
    sleep 20
    get_text('css=div[id="breadCrumbs"]') == "Patient Billing and Accounting Home › Document Search"
  end
  def pba_refund(options={})
    if options[:after_discharge]
      click("//input[@value='Refund']", :wait_for => :page)
    else
      click "link=Refund", :wait_for => :page
    end
    type "textSearchEntry", options[:entry] if options[:entry]
    click "refundMisc" if options[:misc]
    type "soaNo", options[:soa_no] if options[:soa_no]
    type "orNo", options[:or_no] if options[:or_no]
    sleep 1
    select "refundReasonCodeInput", options[:reason] if options[:reason]
    select "refundStatusCodeInput", options[:status] if options[:status]
    sleep 1
    type "receivedBy", "SELENIUM"
    type "validId", "SELENIUM"
    if options[:submit]
      choose_ok_on_next_confirmation if is_confirmation_present
      click "submitButton", :wait_for => :page
    elsif options[:submit_and_print]
      choose_ok_on_next_confirmation if is_confirmation_present
      click "printButton", :wait_for => :page
    end
    sleep 5
    get_confirmation if is_confirmation_present
    return get_text"successMessages" if options[:successful_refund]
  end
  def pba_outpatient_computation(options ={})
    go_to_patient_billing_accounting_page
    if options[:philhealth_multiple_session]
      click("link=PhilHealth Multiple Session", :wait_for => :page)
    elsif options[:pba_special_ancillary]
      click("link=PBA Special Ancillary", :wait_for => :page)
    else
      click "link=PhilHealth DAS/SPU", :wait_for => :page
      type "searchString", options[:pin]
      click "search", :wait_for => :page
      pin = return_original_pin(options[:pin])
      return false if !(is_text_present(pin))
      click_latest_philhealth_link_for_outpatient
      is_text_present(pin)
    end
  end
  def pba_adjustment_and_cancellation(options ={})
    go_to_patient_billing_accounting_page
    if options[:partial]
      click "link=Partial Discounts", :wait_for => :page
    else
      click "link=Adjustment and Cancellation", :wait_for => :page
    end
    select "documentTypes", options[:doc_type] if options[:doc_type]
    sleep 5
    select "searchOptions", options[:search_option] if options[:search_option]
    if options[:search_option] == "DOCUMENT DATE"
      type "dateSearchEntry", options[:entry] if options[:entry]
    else
      type "textSearchEntry", options[:entry] if options[:entry]
    end
    sleep 2
    click "actionButton", :wait_for => :page
    return get_text("css=#refundTableBody").include? "Display Details" if options[:doc_type] == "REFUND"
    return get_text("css=#philhealthTableBody").include? "Reprint PhilHealth Form" if options[:doc_type] == "PHILHEALTH"
    return get_text("css=#orTableBody").include? "Re-print OR" if options[:doc_type] == "OFFICIAL RECEIPT"
    return get_text("css=#processedDiscountsBody").include? "Reprint Prooflist" if options[:doc_type] == "DISCOUNT"
    return get_text("css=#rbTableBody").include?"Cancel" if options[:doc_type] == "ROOM AND BOARD"
    return get_text("css=#chargeInvoiceTableBody").include? "Reprint CI" if options[:doc_type] == "CHARGE INVOICE"
    return get_text("css=#cinoSearchResults").include? "Reprint CI" if options[:doc_type] == "CI NO"
    return get_text("css=#").include? "Reprint" if options[:doc_type] == "OFFICIAL SOA" # not finished yet
  end
  def cancel_or(options={})
    reason = options[:reason] # || "CANCELLATION - EXPIRED"
    click("link=Cancel OR", :wait_for => :page)
    select("selectCancellationReason", "label=#{reason}")
    if options[:reprint]
      click("//input[@value='Reprint']", :wait_for => :page)
      click("popup_ok", :wait_for => :page)
      message = is_text_present("The OR was successfully updated with printTag = 'Y'.")
      present = is_element_present("textSearchEntry")
      return message && present
    elsif options[:cancel]
      click("//input[@value='Cancel']", :wait_for => :page)
      message = is_text_present("Patient Billing and Accounting Home › Document Search")
      present = is_element_present("textSearchEntry")
      return message && present
    elsif options[:submit]
      choose_ok_on_next_confirmation
      click("//input[@value='Submit']", :wait_for => :page)
      get_confirmation()
      return false if is_text_present("Only authorized users are allowed to cancel payments.")
      return true if is_text_present("Patient Billing and Accounting Home")
    end
  end
  def click_refund(options={})
    click("//a[@href='/pba/refund/posRefundForm.html?orNo=#{options[:doc_number]}']", :wait_for => :page)
  end
  def cancel_refund(options={})
    if options[:refund_number]
      click("//a[@href='/pba/refund/refundCancellation.html?refundSlipNo=#{options[:refund_number]}']", :wait_for => :page)
      a = is_text_present("Refund Slip Details")
    end
    click("//input[@value='Submit']", :wait_for => :page) if options[:submit]
    b = is_text_present("Refund Slip #{options[:refund_number]} successfully cancelled.")
    c = get_confirmation if is_confirmation_present
    return a && b if options[:submit] && options[:refund_number]
    return a if options[:refund_number]
    return is_element_present("criteria")
  end
  def click_print_refund_slip
    click("link=Print Refund Slip", :wait_for => :page)
    click("popup_ok", :wait_for => :page) if is_element_present("popup_ok")
    is_text_present("Patient Billing and Accounting Home › Document Search")
  end
  def click_reprint_ci
    click("link=Reprint CI", :wait_for => :element, :element => "documentSearchForm")
    is_text_present("Patient Billing and Accounting Home › Document Search")
    sleep 10
  end
  def cancel_discount
    click "dRadio-0"
    click("closeDiscountDetail") if is_visible("closeDiscountDetail")
    get_value("dRadio-0") == "on"
    click("cancelBtn")
    sleep 5
    type("cancelReasonTxt", "discount cancel reason")
    click("//input[@onclick='DiscountCancellation.validate();' and @value='Continue']", :wait_for => :page)
    is_text_present("Discount Information")
  end
  def view_and_reprinting(options={})
    click "link=#{options[:page]}", :wait_for => :page
    is_text_present("Patient Billing and Accounting Home › Document Search")
    select "//select[@id='documentType']", "label=#{options[:doc_type]}" if options[:doc_type]
    select "searchOption", "label=#{options[:search_option]}" if options[:search_option]
    select "searchOptions", "label=#{options[:search_options]}" if options[:search_options]
    type "textSearchEntry", options[:search_entry]
    click "actionButton", :wait_for => :page
    is_text_present(options[:search_entry])
  end
  def click_display_details(options={})
    click "//a[@href='/pba/discount.html?referenceNo=#{options[:visit_no]}&discountNo=#{options[:discount_no]}&status=active']", :wait_for => :page if options[:inpatient]
    click "//a[@href='/pba/outPatientDiscount.html?referenceNo=#{options[:visit_no]}&discountNo=#{options[:discount_no]}&status=active']", :wait_for => :page if options[:outpatient]
    click "//a[@href='/pba/partialDiscount.html?referenceNo=#{options[:visit_no]}&discountNo=#{options[:discount_no]}&status=active']", :wait_for => :page if options[:partial]
  end
  def reprint_actions(page)
    select 'css=#philhealthTableBody>tr.even>td:last-child>select[name="action"]', "label=#{page}"
    click "actionButton", :wait_for => :page
  end
  def adjust_discount(options={})
    amount = options[:amount]
    click("adjustBtn", :wait_for => :page)
    sleep 5
    click("dRadio-0")
    sleep 3
    click("editScope")
    sleep 3
    type("fixedType", amount)
    click("addScopeBtn")
    sleep 20
    row_count = get_css_count("css=#tableScopes>tr")
    click("saveBtn", :wait_for => :page)
    return row_count
  end
  def add_recommendation_entry(options={})
    click("expressDischarge1") if (options[:express_discharge] and (is_checked("expressDischarge1") == false))
    type("escNumber", options[:esc_no]) if options[:esc_no]
    select("clinicCode", options[:dept_code]) if options[:dept_code]
    type("patientShare", options[:patient_share]) if options[:patient_share]
    type("pcso", options[:pcso]) if options[:pcso]
    if options[:amount]
      click("//input[@type='button' and @value='Add']", :wait_for => :visible, :element => "searchBenefactorButton")
      click("searchBenefactorButton", :wait_for => :visible, :element => "bp_entity_finder_key")
      type("bp_entity_finder_key", options[:benefactor_code]) if options[:benefactor_code]
      click("//input[@type='button' and @onclick='BusinessPartner.search();' and @value='Search']")
      sleep 5
      click("css=#bp_finder_table_body>tr>td", :wait_for => :not_visible, :element => "bp_finder_table_body")
      type("remarks", "sample remarks")
      type("coverageAmount", options[:amount]) if options[:amount]
      click("//input[@type='button' and @onclick='AddCoPayorForm.addBenefactorToList();' and @value='Add Benefactor']", :wait_for => :element, :element => "css=#coPayorTableData>tr>td")
    end
    click("//input[@type='submit' and @value='Submit']", :wait_for => :page)
    is_text_present("Social Service Home")
  end
  def truncate_to(num,decimals=0)
    factor = 10.0**decimals
    (num*factor).floor / factor
  end
  def ss_update_guarantor(options={})
    click'//input[@type="radio" and @name="guarantorId"]'
    click_update_guarantor
    pba_update_guarantor options
    click"expressFlag1" if options[:flag]
    pba_update_account_class(options[:guarantor_type]) if options[:update_acct_class]
    submit_button = is_element_present('//input[@type="submit" and @value="Submit Changes"]') ? '//input[@type="submit" and @value="Submit Changes"]'  :  '//input[@type="submit" and @value="Save"]'
    click(submit_button, :wait_for => :page)
    sleep 8
    (get_text"successMessages") == "The Patient Info was updated."
  end
  def go_to_pba_action_page(options ={})
    select "userAction#{options[:visit_no]}", options[:page]
    click "//input[@type='button' and @value='Submit']", :wait_for => :page
  end
  def pba_document_search_view_and_reprinting(options={})
    click "link=View and Reprinting"
    sleep 2
    click "link=#{options[:soa]}", :wait_for => :page if options[:soa]
    click'//html/body/div/div[2]/div[2]/div[2]/div/div/ul/li[4]/ul/li[5]/a', :wait_for => :page if options[:refund]
    select_button = (is_element_present"//select[@id='documentType']") ? "//select[@id='documentType']" :  "documentTypes"
    select select_button, "label=#{options[:doc_type]}" if options[:doc_type]
    select "searchOptions", "label=#{options[:search_options]}" if options[:search_options]
    type "textSearchEntry", options[:entry] if options[:entry] && (is_element_present("textSearchEntry"))
    click "actionButton", :wait_for => :page
    if options[:soa]
      sleep 5
      click"css=#documentSearchResults>table>tbody>tr.even>td:nth-child(7)>div>a"
      click"itemizedSoaRadio" if options[:itemized]
      click"summarizedSoaRadio" if options[:summarized]
          if options[:cancel]
            click'_cancel', :wait_for => :page
          elsif options[:submit]
            click'_submit', :wait_for => :page
          end
     elsif options[:refund]
     click"css=#refundTableBody>tr.even>td:nth-child(9)>div>a"
     sleep 10
     click"popup_ok", :wait_for => :page if is_element_present"popup_ok"
          if options[:print]
            sleep 1
            click"popup_ok", :wait_for => :page if is_element_present"popup_ok"
            sleep 15 #increasing sleep by 10
            (get_text"successMessages") == "The REFUND was successfully updated with printTag = 'Y'."
          end
    end
     sleep 5
    click"popup_ok", :wait_for => :page if is_element_present"popup_ok"
    is_text_present"Document Search"
  end
  def delete_discount
    click"id=dRadio-0"
    click"id=deleteScope"
    sleep 3
    choose_ok_on_next_confirmation if is_confirmation_present
    sleep 1
    (is_element_present"id=scopeRow-0") == false
  end
  def view_and_reprinting_batch_soa(options={})
    go_to_patient_billing_accounting_page
    click'//html/body/div/div[2]/div[2]/div[2]/div/div/ul/li[4]/ul/li[5]/a', :wait_for => :page
    click"itemized" if options[:itemized]
    click"summarized" if options[:summarized]
    click"//input[@type='button' and @onclick='OSF.show();']"
    type"osf_entity_finder_key",options[:nursing_unit] || "0287"
    click"//input[@type='button' and @value='Search']"
    select"accountClass",options[:account_class] || "INDIVIDUAL"
    type"dateFrom",options[:date] || Time.now.strftime("%m/%d/%Y")
    sleep 1
    #note: for print to pdf - this takes too long, for print to printer - no printer configuration the below process can't be perform
    click"_submitPdf" if options[:pdf]
    click"_submitPrinter" if options[:printer]
    is_text_present"Batch Printing of Statement of Account"
  end
  def miscellaneous_payment_data_entry(options={})
    go_to_miscellaneous_payment_page
    sleep 1
    if options[:ar]
      click"arPayment"
      sleep 1
      select"accountGroup",options[:acct_group] || "INDIVIDUAL WITH BALANCE"
      click"findGuarantor", :wait_for => :element, :element => "patientFinderForm"
      type"patient_entity_finder_key",options[:pin]
      click"//input[@type='button' and @onclick='PF.search();' and @value='Search']", :wait_for => :element, :element => "css=#patient_finder_table_body>tr.even>td>a"
      click"css=#patient_finder_table_body>tr.even>td>a" if is_visible "css=#patient_finder_table_body>tr.even>td>a"
      sleep 1
    elsif options[:misc]
      click"miscPayment"
      sleep 1
      select"miscType",options[:misc_type] || "A/P OTHERS - PATIENTS"
      type"receivedFrom",options[:received_from]
      type"payeeName",options[:pin]
    end
    sleep 1
    type"assignment","assignment"  if options[:assignment]

    if options[:doctor]
      sleep 2
      click"postingDF"
      sleep 1
      type"ddf_entity_finder_key",options[:doctor_code] || "0126"
      click"//input[@type='button' and @onclick='DDF.search();' and @value='Search']"
      sleep 1
      click"css=#ddf_finder_table_body>tr>td>div", :wait_for => :element, :element=> "miscAccountCode"
      sleep 1
      click"doctorAddButton"
      sleep 1
      (get_text"css=#miscDoctorRows>tr>td") == options[:doctor_code] || "0126"
    end

    if options[:tenant]
      sleep 1
      click"postingDF"
      sleep 1
      type"tenant_entity_finder_key",options[:tenant_code] || "BPI001"
      click"//input[@type='button' and @onclick='TF.search();' and @value='Search']"
      sleep 2
      click"css=#tenant_finder_table_body>tr>td>a", :wait_for => :element, :element=> "miscAccountCode"
      sleep 1
      (get_value"css=#miscAccountCode") == options[:tenant_code] || "BPI001"
    end

    type"particulars","particulars"

      if options[:submit]
          if options[:cash]
                click"cashPaymentMode1"
                sleep 3
                type"cashAmountInPhp", options[:amount]
                type"cashBillAmount", options[:amount]
          end
          if options[:vat]
            sleep 3
                vat_amount = get_text('//*[@id="vat"]')
                vat = ((options[:amount] - (options[:amount] / 1.12)) * 10**2).round.to_f / 10**2
                vat_amount = (vat_amount).to_f
                vat = (vat).to_f
                puts vat_amount
                puts vat
                if vat_amount == vat
                      sleep 3
                      click"save" if is_element_present("save")
				    click "name=save" if is_element_present("name=save")
				    sleep 3						
                else
                      return false
                end
           else
                     sleep 3
                     click"save" if is_element_present("save")
				  click "name=save" if is_element_present("name=save")
				  sleep 3		
          end
          click"cancel", :wait_for => :page if options[:cancel]
          click "name=myButtonGroup" if is_element_present"name=myButtonGroup"
          sleep 3
          click "id=popup_ok"
          sleep 3
          click "id=tagOr" 
		 sleep 5			

          return true if (is_text_present"The Official Receipt print tag has been set as 'Y'.") || (is_text_present"Miscellaneous Payment Page")
      end
  end
  def misc_payment_content(options={})
    select"miscType",options[:misc_type]
    sleep 2
    (is_text_present"Miscellaneous Type") == true
    (is_text_present"Received From:") == true
    (is_text_present"Patient Name:") == true
    (is_text_present"Total Cash") == true
    (is_text_present"Total Check") == true
    (is_text_present"Total Card") == true
    (is_text_present"Total Bank Remittance") == true
    (is_text_present"Total GC") == true

    (is_element_present"miscType") == true
    (is_element_present"receivedFrom") == true
    (is_element_present"payeeName") == true
    (is_element_present"particulars") == true
    (is_element_present"cashPaymentMode1") == true
    (is_element_present"checkPaymentMode1") == true
    (is_element_present"creditCardPaymentMode1") == true
    (is_element_present"bankRemittanceMode1") == true
    (is_element_present"//input[@type='submit' and @value='Proceed with Payment']") == true
    (is_element_present"//input[@type='submit' and @value='Cancel']") == true
    content = ((is_text_present"Particulars:*") == true)

    if options[:cost_center]
      (is_element_present"profitCenter") == true
      (get_attribute"profitCenter@readonly") == "true"
      (is_element_present"profitCenterDisplay") == true
      cost_center = ((is_text_present"Cost Center:*") == true)
    end

    if options[:assignment]
      (is_element_present"assignment") == true
      assignment = ((is_text_present"Assignment:*") == true)
    end

    if options[:doctor]
      (is_text_present"Doctor's Name:") == true
      (is_element_present"doctorAddButton") == true
      (is_element_present"doctorDiv") == true
      (is_element_present"postingDF") == true
      doctor = ((is_text_present"Doctor's Code:*") == true)
    end

    if options[:tenant]
      (is_text_present"Tenant") == true
      tenant = ((is_text_present"Tenant's Code:* ") == true)
    end

    return cost_center if options[:cost_center]
    return assignment if options[:assignment]
    return doctor if options[:doctor]
    return content if options[:misc_type]
    return tenant if options[:tenant]
  end
  def check_discharge_datetime(options={})
       visit = options[:visit]
        Database.connect
                         t = "SELECT TO_CHAR(ADMIN_DC_DATETIME,'MM/DD/YYYY HH:MM') FROM TXN_ADM_DISCHARGE WHERE VISIT_NO = '#{visit}'"
                         adm_date_time = Database.select_all_statement t
                         puts adm_date_time
                         s = "SELECT TO_CHAR(DISCHARGE_DATETIME,'MM/DD/YYYY HH:MM') FROM TXN_ADM_ENCOUNTER WHERE VISIT_NO = '#{visit}'"
                         encounter_date_time = Database.select_all_statement s
                         puts encounter_date_time
        Database.logoff
        if adm_date_time == encounter_date_time
                return true
        else return false
        end
  end
end
