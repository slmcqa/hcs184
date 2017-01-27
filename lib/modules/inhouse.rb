#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module InHouse
include Locators::Inhouse

  def go_to_inhouse_page(page, pin)
    select "userAction#{pin}", "label=#{page}"
    click Locators::Inhouse.inhouse_submit_button
    sleep 10 if page != "Billing Notice" || page != "Endorsement Tagging"
    wait_for_page_to_load if page == "Billing Notice" || page == "Endorsement Tagging"
  end
  def inhouse_search(options = {})
    go_to_in_house_landing_page
    patient_pin_search options
    return is_text_present("NO PATIENT FOUND") if options[:no_result]
    endorsement = is_element_present("btnClose") if options[:endorsement]
    click("btnClose") if options[:endorsement]
    return endorsement
  end
  def redtag_patient(options={})
    click Locators::Inhouse.flag if options[:flag]
    type Locators::Inhouse.remarks, options[:remarks]
    click Locators::Inhouse.save if options[:save]
    return get_alert if is_alert_present
    wait_for_page_to_load if options[:save]
    click Locators::Inhouse.exit if options[:exit]
    get_text("successMessages") if options[:save]
  end
  def view_endorsement_history(options={})
    click("link=View Endorsement History")
    sleep 3
    if options[:no_result]
      result = is_text_present("0 item(s). Displaying 0 to 0.")
    end
    click("//div[@id='divEndorsementHistoryPopupTitle']/a")
    return result
  end
  def endorsement_tagging(options={})
    if options[:add]
      click("link=Endorsement Tagging", :wait_for => :page) if is_element_present("link=Endorsement Tagging")
      if (get_text("css=#saved_endorsement_table>tbody>tr") != "No endorsement saved.")
        count = get_css_count("css=#saved_endorsement_table>tbody>tr")
      else
        count = 0
      end
      click("//input[@value='ADD' and @name='btnAddNew']", :wait_for => :element, :element => "add_endorsementType")
      select("add_endorsementType", options[:endorsement_type]) # "UNSETTLED ACCOUNTS", "SPECIAL ARRANGEMENTS", "TAKE HOME MEDICINES", "WAIVED ADDITIONAL ROOM AND BOARD"
      wait_for(:wait_for => :not_present, :text => "ADMISSION")
      wait_for(:wait_for => :text, :text => "ADMISSION")
      type("endorsement_textarea", options[:endorsement_detail] || "Selenium Endorsement")
      sleep 5
      add_selection("destination_select", "BILLING") if options[:billing]
      add_selection("destination_select", "IN HOUSE COLLECTIONS") if options[:inhouse]
      add_selection("destination_select", "DIVISION OF NURSING") if options[:don]
      add_selection("destination_select", "ADMISSION") if options[:admission]
      sleep 1
      click("//input[@value='CLOSE' and @name='btnClose']") if options[:close]
      click("//input[@value='SAVE' and @name='btnSave']", :wait_for => :page) if options[:save]
      return get_text("css=#endorsementDisplay_#{count}>table>tbody>tr>td").gsub('Endorsement Type:  ', '') == options[:endorsement_type]
    elsif options[:edit]
      click("//img[@title='Edit']")
      sleep 2
      select("edit_endorsementType_0", options[:endorsement_type])
      sleep 5
      select("destination_select_0", options[:recipient]) if options[:recipient]
      click("//img[@title='Cancel']") if options[:cancel]
      click("//img[@title='Save']") if options[:save]
    elsif options[:delete]
      click("//img[@title='Delete']") 
      sleep 10
      return is_text_present("No endorsement saved.") if options[:delete]
      return get_text("//div[@id='endorsementDisplay_0']/table/tbody/tr/td").gsub("Endorsement Type:  ", "") == options[:endorsement_type]
    else
      click("link=Endorsement Tagging", :wait_for => :page)
      return get_text("//table[@id='saved_endorsement_table']/tbody/tr/td")
    end
  end
  def endorsement_tagging_print_prooflist
    click("btnPrintEndorsementId", :wait_for => :page)
    a = is_text_present("Prooflist printed successfully")
    b = is_element_present("banner.visitNo")
    return a && b
  end
  def view_patients_tagged_with_endorsements
    click("patientsWithEndorsementCount")
    sleep 10
    result = get_text("endorsementSummaryMessages")
    click("//input[@onclick='closeEndorsementSummaryDialog();' and @value='Close']")
    return result
  end
  def inhouse_view_and_reprinting(options={})
    click "link=View and Reprinting"
    sleep 2
    click "link=#{options[:select]}", :wait_for => :page
    if options[:select] == "Batch Billing Notice"
      type("criteria", options[:entry])
      click("searchBtn", :wait_for => :page)
      click("//input[@onclick='closeEndorsementDialog();' and @value='Close' and @name='btnClose']") if options[:endorsement]
      click("tag-#{options[:visit_no]}")
      click("link=Generate Selected Billing Notice", :wait_for => :page)
      return is_element_present("criteria")

    elsif options[:select] == "Batch Unofficial SOA"
      click("itemized") if options[:itemized]
      click("summarized") if options[:summarized]
      click("both") if options[:both]
      if options[:org_code]
        click("//input[@onclick='OSF.show();']", :wait_for => :element, :element => "osf_entity_finder_key")
        type("osf_entity_finder_key", options[:org_code])
        click("//input[@onclick='OSF.search();' and @value='Search']", :wait_for => :element, :element => "link=#{options[:org_code]}")
        click("link=#{options[:org_code]}", :wait_for => :not_visible, :element => "link=#{options[:org_code]}")
      end
      select("accountClass", options[:account_class]) if options[:account_class]
      if options[:guarantor_code]
        click("//input[@onclick='GuarantorInformation.show();']", :wait_for => :element, :element => "gi_entity_finder_key")
        type("gi_entity_finder_key", options[:guarantor_code])
        click("//input[@onclick='GuarantorInformation.search();' and @value='Search']", :wait_for => :element, :element => "link=#{options[:guarantor_code]}")
        click("link=#{options[:guarantor_code]}", :wait_for => :not_visible, :element => "link=#{options[:guarantor_code]}")
      end
      type("dateFrom", options[:date_from] || Time.now.strftime("%m/%d/%Y"))
      type("dateTo", options[:date_to]) if options[:date_to]
      click("//input[@value='Print to Printer']", :wait_for => :page) if options[:print_to_printer]
      click("//input[@value='Print to PDF']", :wait_for => :page) if options[:print_to_pdf]
      click("//input[@value='Clear']") if options[:clear]
      sleep 3 if options[:clear]
      return get_text("errorMessages") if is_element_present("errorMessages")
      return get_text("successMessages") if is_element_present("successMessages")
    elsif options[:select] == "Red Tag"
      select("reportTypeField", options[:report_name]) if options[:report_name]
      type("startDate", options[:start_date] || Time.now.strftime("%m/%d/%Y"))
      type("endDate", options[:end_date]) if options[:end_date]
      click("clearBtn") if options[:clear]
      click("printBtn", :wait_for => :page) if options[:print]
      click("viewBtn", :wait_for => :page) if options[:view]
      click("closeBtn", :wait_for => :page) if options[:close]

      return is_element_present("redTagPatients") if options[:view]
      return get_text("successMessages") if options[:print]
      return is_element_present("criteria") if options[:close]

    elsif options[:select] == "Generation of SOA"
      select("searchOptions", options[:search_options])
      type("textSearchEntry", options[:entry]) if options[:entry]
      click("actionButton", :wait_for => :page)
      click("link=Reprint SOA", :wait_for => :element, :element => "//input[@onclick='submitForSOA();']")
      click("//input[@onclick='submitForSOA();']", :wait_for => :page)
      click("popup_ok", :wait_for => :page)

      return get_text("successMessages")
    end
  end

end