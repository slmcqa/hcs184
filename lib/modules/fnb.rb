#!/bin/env ruby
# encoding: utf-8
module FNB
   # extracted fnb-specific methods from existing nurging gu module
  def go_to_fnb_page_given_pin(page, pin)
    select "userAction#{pin}", "label=#{page}"
    click Locators::ARMS.submit, :wait_for => :page
  end
  def create_fnb_order(options ={})
    if options[:supplements]
      click "orderType"
      type "oif_entity_finder_key", options[:fnb_service]
      sleep 2
      click "search", :wait_for => :element, :element => "link=#{options[:fnb_service]}"
      sleep 1
      type "itemDesc", options[:item_desc] || options[:fnb_service] || "apple juice"
      type "serviceRateStr", options[:service_rate] || "100.00"
      type "doctorCode", options[:doctor] || "0001"
      type "remarks", options[:remarks] || "remarks"
    end
    if options[:special]
      click "orderTypeFnb9999"
      fnb_service = options[:fnb_service] || "special item test"
      type("itemDesc", fnb_service)
      click "//input[@value='FIND']"
      type "entity_finder_key", "ABAD" || options[:doctor]
      click "//input[@value='Search']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
      sleep 1
      click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
      click "btnFindPerfUnit", :wait_for => :visible, :element => "osf_entity_finder_key"
      type "osf_entity_finder_key", "0278" if (CONFIG['location'] == 'GC')
      type "osf_entity_finder_key", "0332" if (CONFIG['location'] == 'QC')
      click "//input[@value='Search' and @type='button' and @onclick='PUF.search();']", :wait_for => :element, :element => "css=#osf_finder_table_body>tr>td>a"
      sleep 1
      click "css=#osf_finder_table_body>tr>td>a", :wait_for => :not_visible, :element => "css=#osf_finder_table_body>tr>td>a"
    end
    sleep 5
    item_code = get_value Locators::FNB.searched_item_code if options[:supplements]
    item_description = get_value Locators::FNB.searched_item_description if options[:supplements]
    add_button = is_element_present("//input[@value='ADD']") ? "//input[@value='ADD']" : "//input[@value='Add']"
    click add_button, :wait_for => :page
    sleep 5
    c1 = is_text_present("Order item #{item_code} - #{item_description} has been added successfully.") if options[:supplements]
    c1 = is_text_present("Order item 9999 - #{fnb_service} has been added successfully") if options[:special]
    if options[:save]
      click "saveCart", :wait_for => :page
      sleep 3
    end
    return c1
  end
  def create_and_edit_fnb_order(options ={})
    if options[:supplements]
      click "orderType"
      type "oif_entity_finder_key", options[:fnb_service]
      click "search", :wait_for => :ajax
      type "doctorCode", options[:doctor] || "6726"
      type "remarks", "remarks"
      sleep 5
      item_desc = options[:item_desc] || ""
      type("itemDesc", item_desc)
      service_rate = options[:service_rate] || ""
      type("serviceRateStr", service_rate)
    end
    if options[:special]
      click "orderTypeFnb9999"
      fnb_service = options[:fnb_service] || ""
      type("itemDesc", fnb_service)
      click "//input[@value='FIND']"
      type "entity_finder_key", "abad"
      click "//input[@value='Search']"
      sleep 3
      click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
      sleep 3
      click "//input[@value='Search' and @type='button' and @onclick='PUF.search();']"
      type "osf_entity_finder_key", "0278" if (CONFIG['location'] == 'GC')
      type "osf_entity_finder_key", "0332" if (CONFIG['location'] == 'QC')
      click "//input[@value='Search' and @type='button' and @onclick='PUF.search();']"
      sleep 2
      click "//html/body/div/div[2]/div[2]/div[6]/div[2]/div[2]/div[2]/table/tbody/tr/td[2]/a"
    end
    sleep 5
    add_button = is_element_present("//input[@value='ADD']") ? "//input[@value='ADD']" : "//input[@value='Add']"
    click add_button, :wait_for => :page
  end
  def go_to_fnb_diet_stub_page
    click "link=Diet Stub", :wait_for => :page
    return get_text("//html/body/div/div[2]/div[2]/div/div/ul/li[2]") == "Search Diet Stubs for Admitted Patients"
  end
  # this is displayed when page is in fnb order page
  def go_to_fnb_patient_search_page
    click "link=Patient Search Page", :wait_for => :page
    return get_text("//html/body/div/div[2]/div[2]/div[2]/div/div/div/ul/li/a") == "Diet Stub"
  end
  def search_fnb_diet_stub(options ={})
    select "perAdmittedPatientSearchForm.nursingUnitCode", "label=#{options[:label]}"
    if options[:advanced_search]
      click "slide-fade"
      type "perAdmittedPatientSearchForm.pin", options[:pin] if options[:pin]
      type "perAdmittedPatientSearchForm.name.lastName", options[:last_name] if options[:last_name]
      type "perAdmittedPatientSearchForm.visitNo", options[:visit_no] if options[:visit_no]
      #click "//input[@value='Search' and @type='button']", :wait_for => :page
    end
    click "searchAdmittedPatients", :wait_for => :page
    return get_text("//html/body/div/div[2]/div[2]/form/div/div/div[3]/table/tbody/tr/td") == "Nothing found to display." if options[:no_result]
    return (get_text("//html/body/div/div[2]/div[2]/form/div/div/div[3]/table/tbody/tr/td[2]/b") == options[:last_name].upcase) if options[:last_name]
  end
  def view_patient_diet_stub
    click 'viewAdmittedPatientStub', :wait_for => :page
    is_text_present "Search Diet Stubs for Admitted Patients"
  end
  def print_patient_diet_stub
    click 'printAdmittedPatientStub', :wait_for => :page
    is_text_present "Search Diet Stubs for Admitted Patients"
  end
  def view_all_diet_stub
    if is_element_present("//html/body/div/div[2]/div[2]/form/div/div/div[3]/input")
      click "viewAllAdmittedPatientStubs", :wait_for => :page
      return is_text_present "Search Diet Stubs for Admitted Patients"
    end
  end
  def print_all_diet_stub
    if is_element_present("//html/body/div/div[2]/div[2]/form/div/div/div[3]/input[2]")
      click "printAllAdmittedPatientStubs", :wait_for => :page
      # temporary check for staging environment (without configured printer)
      return (get_text("//html/body/div/div[2]/div[2]/div[3]/div") == "Unable to find printer map for DIET_STUB_PRINTER")
    end
  end
  def count_diet_history (options={})
    click"//input[@type='button' and @value='View Diet History']", :wait_for => :page if options[:view_diet_history]
    count = get_css_count "css=#dataTable>tbody>tr" # plus header
    back_button = is_element_present("//a[@href='/nursing/general-units/generalUnitsClinicalDiet.html?pin=#{options[:pin]}&visitNo=#{options[:visit_no]}']") ?  "//a[@href='/nursing/general-units/generalUnitsClinicalDiet.html?pin=#{options[:pin]}&visitNo=#{options[:visit_no]}']" :  "//a[@href='/nursing/special-units/erClinicalDiet.html?pin=#{options[:pin]}&visitNo=#{options[:visit_no]}']"
    click(back_button, :wait_for => :page)   if options[:back]
    return count
  end

end