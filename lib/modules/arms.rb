#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module Arms
  include Locators::Login
  include Locators::ARMS

  def create_signatory(physician)
    click "link=Digital Signature Data Entry", :wait_for => :page
    click "//img[@alt='Search']"
    click "//input[@value='Search']"
    click "link=#{physician}"
    click "file"
    type "file", "/home/girlie/Pictures/St.-Lukes-Medical-Center.jpg"
    click "save"
    type "criteria", physician
    click "search"
  end
  def search_document(pin)
    type "pinLastName", pin
    click "//input[@value='Search']", :wait_for => :page
    is_element_present("css=#results>tbody>tr")
  end
  def medical_search_patient(pin)
    while is_element_present("btnOK") && is_visible("btnOK")
      click("btnOK") if is_element_present("btnOK")
    end
    sleep 5
    type("param", pin)
    click("search", :wait_for => :page)
  end
  def advance_medical_search_patient(options={})
    click_advanced_search
    type("param", options[:last_name])
    type("firstName", options[:first_name]) if options[:first_name]
    type("middleName", options[:middle_name]) if options[:middle_name]
    type("birthDate", options[:birth_day]) if options[:birth_day]
    click("//input[@value='M' and @name='gender']") if options[:gender] == "M"
    click("//input[@value='F' and @name='gender']") if options[:gender] == "F"
    click("//input[@name='search' and @value='Search']", :wait_for => :page)
  end
  def click_results_data_entry
    click Locators::ARMS.results_data_entry, :wait_for => :page
  end
  def perform_results_data_entry(options={})
    click_results_data_entry
    type Locators::ARMS.remarks, "remarks"

    ## set 1st signatory value
    click Locators::ARMS.signatory1
    type Locators::ARMS.signatory1_id, options[:signature1]
    click Locators::ARMS.search_signatory1, :wait_for => :element, :element => "link=#{options[:signature1]}"
    click "link=#{options[:signature1]}"
    sleep 5

    ## set 2nd signatory value
    if options[:signature2]
      click Locators::ARMS.signatory2
      type Locators::ARMS.signatory2_id, options[:signature2]
      click Locators::ARMS.search_signatory2, :wait_for => :element, :element => "link=#{options[:signature2]}"
      click "link=#{options[:signature2]}"
      sleep 5
    end
  end
  def click_reset
    click "//input[@name='reset' and @value='Reset']"
    sleep 5
  end
  def arms_click_update
    click "//input[@name='a_update2' and @value='Update']", :wait_for => :page
  end
  def save_signatories
  ## save inputted signatories
    click Locators::ARMS.save, :wait_for => :page
    get_text(Locators::ARMS.document_status) == "CREATED"
  end
  def verify_document_status
    ## verify document status from the order list
    get_text(Locators::ARMS.document_status_list)
  end
  def queue_for_validation
    ## queued document for validation
    fire_event Locators::ARMS.queue_for_validation, "blur"
    while(set_queue_for_validation != "QUEUED")
      Proc.new{self.set_queue_for_validation}
    end
    is_text_present"QUEUED"
  end
  def set_queue_for_validation
    click Locators::ARMS.queue_for_validation#, :wait_for => :page
    sleep 15 # page does not load after clicking, using sleep for now
    get_text(Locators::ARMS.document_status)
  end
  def validate_document
  ## validate the document
    fire_event Locators::ARMS.validate, "blur"
    click Locators::ARMS.validate#, :wait_for => :element, :element => Locators::ARMS.username
    sleep 10
    is_element_present(Locators::ARMS.username)
  end
  def validate_package
    fire_event Locators::Wellness.validate, "blur"
    click Locators::Wellness.validate
    sleep 3
    click '//input[@value="OK" and @onclick="MultiplePrinters.validate(); return false;" and @type="button"]' if is_element_present'//div[@id="multiplePrinterPopup"]'
    sleep 10
    if is_element_present("xpath=(//button[@type='button'])[3]")
      click "xpath=(//button[@type='button'])[3]"
       click Locators::Wellness.validate
       click "id=printButton"
    end
    sleep 4
    is_element_present(Locators::ARMS.username)
  end
  def validate_non_ecu_package
    click '//input[@type="checkbox"]'
    sleep 2
    click '//input[@type="button" and @value="Validate"]'
    sleep 10
    click "//html/body/div[8]/div[11]/div/button", :wait_for => :page if is_element_present "//html/body/div[8]/div[11]/div/button"
    sleep 10
    get_css_count("css=#non-ecu-id-validated-pane>div>div>table>tbody>tr")
  end
  def validate_credentials(options={})
    allowed = options[:allowed]
    type Locators::ARMS.username, options[:username]
    type Locators::ARMS.password, options[:password]
    submit_credentials_and_wait
    # click Locators::ARMS.submit, :wait_for => :page
    if allowed
      return get_text(Locators::ARMS.document_status)
    elsif options[:package]
      sleep 20
      return is_text_present("General Units › Package Management")
    else
      return get_text("errMessage")
    end
  end
  def submit_credentials_and_wait
    click Locators::ARMS.submit #, :wait_for => :page
    sleep 15  # page does not load after clicking, using sleep for now
  end
  def cancel_credentials
    click Locators::ARMS.cancel_credentials, :wait_for => :ajax
  end
  def tag_as_official
  ## tag the validated document as official
    fire_event Locators::ARMS.tag_as_official, "blur"
    click Locators::ARMS.tag_as_official#, :wait_for => :element, :element => Locators::ARMS.username
        if (is_element_present"divTemplatesSelectionPopup") == true
          choose_ok_on_next_confirmation
        end
    sleep 5
    is_element_present(Locators::ARMS.username)
  end
  def official_credentials(options={})
    allowed = options[:allowed]
    choose_ok_on_next_confirmation  if is_element_present'divTemplatesSelectionPopup'
    type Locators::ARMS.username, options[:username]
    type Locators::ARMS.password, options[:password]
    submit_credentials_and_wait
    #click Locators::ARMS.submit, :wait_for => :page
    if allowed
      return get_text(Locators::ARMS.document_status)
    else
      return get_text("errMessage")
    end
  end
  def results_retrieval
    ## verify document status from the list of an official document and view pdf
    click Locators::ARMS.results_retrieval, :wait_for => :page
    ## verify if a pdf file is included in src attribute of the page
    sleep 3
    is_element_present('css=div[id="reportFileDiv"]')
    #pdf = get_attribute 'css=div[id="reportFileDiv"]'
    #pdf.match /\/report\/report.html\?file\=/
  end
  def verify_document_action
    get_text(Locators::ARMS.document_action_list)
  end
  def click_medical_fullname
    click Locators::ARMS.medical_fullname, :wait_for => :page
  end
  #check official document from the medical records
  def verify_medical_record(ci_number)
    get_text("//html/body/div/div[2]/div[2]/div[9]/div[2]/table/tbody/tr/td[4]") == ci_number
  end
  def arms_advance_search(options={})
    click("slide-fade")
    sleep 2
    type("requestStartDate", options[:request_start] || Time.now.strftime("%m/%d/%Y"))
    type("requestEndDate", options[:request_end] || Time.now.strftime("%m/%d/%Y"))
    type "scheduleStartDate", options[:schedule_start]
    type "scheduleEndDate", options[:schedule_end]
    type("ciNumber", options[:ci_number]) if options[:ci_number]
    type("specimenNumber", options[:specimen_number]) if options[:specimen_number]
    type("itemCode", options[:item_code]) if options[:item_code]
    select("documentStatus", "label=#{options[:document_status]}") if options[:document_status]
    select("orderStatus", "label=#{options[:order_status]}") if options[:order_status]
    click "css=#advanceSearchOption>div:nth-child(8)>input", :wait_for => :page if options[:search]
  end
  def assign_signatory(options={})
    if options[:one]
      click("//a[@href='javascript:void(0)' and @onclick='DSF1.show();']")
      sleep 5
      type("sf1_entity_finder_key", options[:code1])
      click "//input[@onclick='DSF1.search();' and @value='Search']"
      sleep 6
      click("link=#{options[:code1]}")
      sleep 3
      return true if (get_value"name1") != ""
    elsif options[:two]
      click("//a[@href='javascript:void(0)' and @onclick='DSF2.show();']")
      sleep 5
      type("sf2_entity_finder_key", options[:code2])
      click "//input[@onclick='DSF2.search();' and @value='Search']"
      sleep 6
      click("link=#{options[:code2]}")
      sleep 3
      return true if (get_value"name2") != ""
    end
  end
  def click_enter_results_for_selected_items
    click "multi_rde", :wait_for => :page
    is_text_present("Patient's Results")
  end
  def verify_search(options = {})
  if options[:with_results]
    c1 = is_element_present "//table[@id='results']/tbody/tr/td"
  elsif options[:no_results]
    c1 = is_text_present "0 found Nothing to Display"
  elsif options[:no_result_rr]
    c1 = is_text_present "NO PATIENT FOUND"
  end
  return c1
  end
  def patient_banner_content
    #is_text_present("Patient's Results")
    sleep 8
    contents = get_text("patientBanner")
    contents.include?(get_text("banner.pin")) == true
    contents.include?(get_text("banner.fullName")) == true
    contents.include?(get_text("banner.gender")) == true
    contents.include?(get_text("banner.birthDate")) == true
    contents.include?(get_text("banner.roomBed")) == true
    contents.include?(get_text("banner.nursingUnit")) == true
    contents.include?(get_text("banner.visitNo")) == true
    contents.include?(get_text("banner.admissionDateTime")) == true
    contents.include?(get_text("banner.admissionDoctor")) == true
    contents.include?(get_text("banner.admissionDiagnosis")) == true
    contents.include?(get_text("banner.patientType")) == true
    contents=get_text("banner.birthDate")
    contents.include?("year")==true
  end
  def rr_content
    contents=get_text("results")
    contents.include?("PIN") == true
    contents.include?("Patient Name") == true
    contents.include?("Exam Date") == true
    contents.include?("Procedure Name") == true
    contents.include?("Performing Unit") == true
    contents.include?("Specimen No.") == true
    contents.include?("Date Requested") == true
    contents.include?("Date/Time Tagged as Official") == true
    contents.include?("Actions") == true
  end
  def search_rr_document(options={})
    type'criteria',options[:pin]
    sleep 4
    if  is_element_present'//input[@id="search" and @value="Search"]'
      click '//input[@id="search" and @value="Search"]', :wait_for => :page
    elsif is_element_present'//input[@id="searchMPI" and @value="Search" and @type="submit"]'
      click'//input[@id="searchMPI" and @value="Search" and @type="submit"]', :wait_for => :page
    else
      click'//input[@type="submit" and @value="Search"]', :wait_for => :page
    end
    return options[:pin]
  end
  def search_non_doc_document(options ={})
    type'param', options[:pin]
    click '//input[@id="search" and @value="Search"]', :wait_for => :page
     if options[:no_result]
        return is_text_present("NO PATIENT FOUND")
     else
        return options[:pin]
     end
  end
  def search_signatory_page(id)
    type 'sf1_entity_finder_key', id if is_element_present 'sf1_entity_finder_key'
    type 'sf2_entity_finder_key', id if is_element_present 'sf2_entity_finder_key'
    search_button = is_element_present('//input[@type="button" and @onclick="DSF1.search();"]') ?  '//input[@type="button" and @onclick="DSF1.search();"]' : '//input[@type="button" and @onclick="DSF2.search();"]'   #@name="action" in 1.4.2
    click search_button
    sleep 2
  end
  #   def search_rr_general_unit(pin)
  #    type'criteria',pin
  #    click '//input[@type="submit" and @value="Search"]', :wait_for => :page
  #   end
  def select_printer
    if is_text_present"0295" ==true
      click 'link=0295'
    else
      is_text_present"0076" ==true
      click 'link=0076'
    end
  end
  def fill_out_form(options={})
    type'name.lastName', options[:last_name]
    type 'name.firstName',  options[:first_name]
    type 'name.middleName',  options[:middle_name]
    day = AdmissionHelper.range_rand(1,29).to_s
    month = AdmissionHelper.range_rand(1, 13).to_s
    year = "19" + AdmissionHelper.range_rand(30,99).to_s
    day = "0" + day if day.length == 1
    month = "0" + month if month.length == 1
    birth_day = "#{month}/#{day}/#{year}"
    type'birthDate',birth_day
    click'gender1'
    click "//input[@name='action' and @value='Save']", :wait_for => :page
  end
  def go_to_patient_result_page(options ={})
    patient_pin_search options
    sleep 2
    select "userAction#{options[:pin]}", "label=Patient Results"
    click Locators::NursingSpecialUnits.submit_button
    sleep 10
  end
  def search_result_page(options = {})
   if options[:with_results]
      click'//input[@type="submit" and @value="Search"]'
   elsif options[:no_results]
     click'//input[@type="submit" and @value="Search"]'
   end
   sleep 20
   return get_text("css=#patientSearchResult>tbody>tr>td")
  end
  def special_units_headings
    get_text("css=#occupancyList>thead>tr>th:nth-child(2)>a") =="Room/Bed No."
    is_text_present"Patient Name"
    is_text_present"Age"
    is_text_present"Gender"
    get_text("css=#occupancyList>thead>tr>th:nth-child(3)>a") =="PIN"
  end
  def arms_special_units
    click'link=Home',:wait_for=>:page
    click'link=Nursing Special Units Landing Page',:wait_for=>:page
    click"css=#left_nav>ul>li>a",:wait_for=>:page
  end
  def validate_result(options={})
    if options[:validate]
      click'//input[@name="a_validate2" and @value="Validate"]'
      sleep 2
      type'validateUsername', options[:username] || 'dcvillanueva'
      type'validatePassword', options[:password] || 'dcvillanueva'
      click'//input[@type="button" and @onclick="UserValidation.validate();" and @value="Submit"]'
      sleep 10
      return true if (get_text'//html/body/div/div[2]/div[2]/form/div[3]/span[3]') == "VALIDATED"
    elsif options[:cancel_validate]
      click'//input[@name="a_validate2" and @value="Validate"]'
      sleep 2
      click'btnValidationCancel'
      return true if (get_text'//html/body/div/div[2]/div[2]/form/div[3]/span[3]') != "VALIDATED"
    else
      click'//input[@name="a_validate2" and @value="Validate"]'
    end
  end
  def tag_official_result(options={})
    if options[:validate]
      click'//input[@type="Button" and @name="a_official2"]'
      choose_ok_on_next_confirmation if is_element_present'divTemplatesSelectionPopup'
      type'validateUsername',options[:username] || 'dasdoc5'
      type'validatePassword','123qweuser'
      click'//input[@type="button" and @onclick="UserValidation.validate();" and @value="Submit"]'
    else
      click'//input[@type="Button" and @name="a_official2"]'
      choose_ok_on_next_confirmation  if is_element_present'divTemplatesSelectionPopup'
    end
  end
  def result_list_advanced_search(options={})
    sleep 8
    if options[:slide]
      click 'slide-fade'
      sleep 2
    end
    if options[:exam_date]
       type "startExamDate", options[:date]
    end
    if options[:procedure]
      click'//a[@onclick="TMF.show();"]'
      sleep 2
      type'tmf_entity_finder_key',options[:procedure_name]#'Vectorcardiography'
      click'//input[@value="Search" and @onclick="TMF.search();"]'
      sleep 6
      click "css=#tmf_finder_table_body>tr.even>td:nth-child(2)>a"
      sleep 2#,:wait_for => :element, :element => "patientSearchResult"
    end
    if options[:performing_unit]
      click'//a[@onclick="PUF.show();"]'
      type'osf_entity_finder_key',options[:unit]#'ECG AND HOLTER'
      click'//input[@value="Search" and @onclick="PUF.search();"]'
      sleep 6
      click"css=#osf_finder_table_body>tr.even>td:nth-child(2)>a"
      sleep 2#,:wait_for => :element, :element => "patientSearchResult"
    end
    if options[:requesting_date]
      type'startRequestDate',options[:date]
    end
    if options[:search]
      click'advancedSearch',:wait_for=>:page
    end
  end
  def search_arms_other_unit(options={})
    patient_pin_search options
    if options[:validate]
      if is_text_present("NO PATIENT FOUND") == true
        patient_pin_search options
      else
        get_text("css=#results>tbody>tr.even>td:nth-child(3)").gsub(' ','') != options[:pin] if is_element_present"css=#results>tbody>tr.even>td:nth-child(3)"
        get_text("css=#occupancyList>tbody>tr.even>td:nth-child(3)").gsub(' ','') != options[:pin]  if is_element_present"css=#occupancyList>tbody>tr.even>td:nth-child(3)"
      end
    end
  end
  def search_dasdoc_other_unit(options={})
    patient_pin_search options
    if options[:validate]
      if is_text_present("NO PATIENT FOUND") == true
        patient_pin_search options
      else
        get_text("css=#results>tbody>tr.even>td").gsub(' ','') != options[:pin]
      end
    end
  end
  def medical_search(options={})
    type "param", options[:pin]
    click "search", :wait_for => :page
    if options[:no_result]
      return is_text_present("NO PATIENT FOUND")
    else
      return options[:pin]
    end
  end
  def medical_contents
    a = (get_text("css=#results>thead>tr>th:nth-child(1)") == "PIN")
    b = (get_text("css=#results>thead>tr>th:nth-child(2)") == "Location")
    c = (get_text("css=#results>thead>tr>th:nth-child(3)") == "Patient Name")
    d = (get_text("css=#results>thead>tr>th:nth-child(4)") == "Age")
    e = (get_text("css=#results>thead>tr>th:nth-child(5)") == "Gender")
    f = (get_text("css=#results>thead>tr>th:nth-child(6)") == "ACTION")
    return (a && b && c && d && e && f) # debugged assertion - junn Nov/02/2011
  end
  def more_options_arms_rr(options = {})
    sleep 8
    click 'slide-fade'
    sleep 2
    if options[:exam_date]
      type "examStartDate", options[:date]
    end
    if options[:requesting_date]
        type "requestStartDate", options[:date]
    end
    if options[:search]
         click'advancedSearch'
         sleep 3
    end
  end
  def click_result_retrieval(options={})
    count = get_css_count("css=#results>tbody>tr")
    if options[:chosen_result]
      count.times do |rows|
        my_row=get_text("css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(4)")
        if my_row == "Vectorcardiography"
          stop_row = rows
          click("css=#results>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(9)>a")
          sleep 10
        end
      end
    end
    sleep 3
    is_element_present('css=div[id="reportFileDiv"]')
  end
  def result_list_search(options={})
    type("startExamDate", options[:start_date]) if options[:start_date]
    type("endExamDate", options[:end_date]) if options[:end_date]
    type("startRequestDate", options[:start_request]) if options[:start_request]
    type("endRequestDate", options[:end_request]) if options[:end_request]
    if options[:test_procedure]
      click("//a[@onclick='TMF.show();']", :wait_for => :visible, :element => "tmf_entity_finder_key")
      sleep 1
      type("tmf_entity_finder_key", options[:test_procedure])
      click("//input[@onclick='TMF.search();']", :wait_for => :element, :element => "link=#{options[:test_procedure]}")
      click("link=#{options[:test_procedure]}", :wait_for => :not_visible, :element => "link=#{options[:test_procedure]}")
      sleep 1
    end
    if options[:performing_unit]
      click("//a[@onclick='PUF.show();']", :wait_for => :visible, :element => "osf_entity_finder_key")
      sleep 1
      type("osf_entity_finder_key", options[:performing_unit])
      click("//input[@onclick='PUF.search();']", :wait_for => :element, :element => "link=#{options[:performing_unit]}")
      click("link=#{options[:performing_unit]}", :wait_for => :not_visible, :element => "link=#{options[:performing_unit]}")
      sleep 1
    end
    click("//input[@type='submit' and @value='Search']", :wait_for => :page) if options[:search]
    is_element_present("css=#patientSearchResult>tbody>tr>td:nth-child(2)>a")
  end
  def search_patient_admission_history(options={})
    type("startAdmissionDate", options[:start_admission]) if options[:start_admission]
    type("endAdmissionDate", options[:end_admission]) if options[:end_admission]
    type("startDischargeDate", options[:start_discharge]) if options[:start_discharge]
    type("endDischargeDate", options[:end_discharge]) if options[:end_discharge]
    click("//input[@type='radio' and @value='I']") if options[:inpatient]
    click("//input[@type='radio' and @value='O']") if options[:outpatient]
    sleep 1
    click("//input[@type='submit' and @value='Search' and @name='search']", :wait_for => :page)
    return get_text("css=#results>tbody>tr>td") if is_element_present("css=#results>tbody>tr>td")
    return is_element_present("css=#patientAdmVisitHistory>tbody>tr>td:nth-child(3)")
  end
  def enter_result_for_selected_items(options={})
    search_document options
    click'//input[@type="checkbox"]'
    click'//input[@id="multi_rde" and @type="button" and @value="Enter Results for Selected Items"]'
    sleep 10
    is_text_present"Patient's Results"
  end
  def arms_result_page(options={})
    search_rr_document(options)
    select "action", "Patient Results"
    click Locators::NursingSpecialUnits.submit_button_spu, :wait_for => :page
    sleep 3
    is_text_present"Result List"
  end
  #added by hanna- search for bug 40047
  def readers_fee_search(options={})#modified 9/21
    select "patientType", "label=#{options[:patient_type]}"
    select "withArmsTemplateFlag", "label=#{options[:arms_template]}"
    click "//input[@name='formAction' and @value='Search']", :wait_for => :page
    if options[:with_result]
      is_text_present(options[:ci_num])
    else
      is_text_present("Nothing found to display.")
    end
  end
  def click_readers_fee_generate_report
    click'//input[@type="submit" and @value="Generate Report" and @name="formAction"]', :wait_for => :page
    is_text_present"Report"
  end
  def view_readers_fee_generate_report(options={})
    click_readers_fee_generate_report
    type'startDate',Time.now.strftime("%m/%d/%Y")
    type'endDate',Time.now.strftime("%m/%d/%Y")
    click'generatePdfReport', :wait_for => :page if options[:pdf]
    click'generateXlsReport', :wait_for => :page if options[:excel]
    is_text_present"Success"
  end
  def switch_non_ecu_package(options={})
    click Locators::Wellness.non_ecu_switch_link, :wait_for => :element, :element => "package-switch-dialog-container"
    sleep 3
    click 'css=#package-switch-dialog-tbody-alternative>tr>td>a>div'
    sleep 1
    if options[:all]
      click '//input[@type="checkbox"]'
    end
    if options[:select_item]
    count = get_css_count("css=#non-ecu-id-onordered-pane>div>div>table>tbody>tr")
    count.times do |rows|
        my_row=get_text("css=#non-ecu-id-onordered-pane>div>div>table>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)")
        if my_row.include? "URINALYSIS"
          stop_row = rows
          click("css=#non-ecu-id-onordered-pane>div>div>table>tbody>tr:nth-child(#{stop_row + 1})>td>input")
        end
      end
    end
  end
end
