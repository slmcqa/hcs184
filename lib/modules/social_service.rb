#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module SocialService
  def ss_search(options={})
    type "criteria", options[:pin]
    click "filter" if options[:with_discharge_notice]
    click "filter1" if options[:discharged]
    click "filter2" if options[:admitted]
    click "filter3" if options[:all_patients] && (is_element_present('filter3'))
    click "withIndividual1" if options[:individual]
    click "search", :wait_for => :page
    sleep 2
    if is_element_present "css=#results>tbody>tr>td:nth-child(4)" #discount adjustment line#87
      visit_no = get_text("css=#results>tbody>tr>td:nth-child(4)").gsub(' ', '' )
      return visit_no
    end
  end
  def ss_update_account_class(options={})
    select "accountClass", "label=#{options[:account_class]}"
    sleep 1
    type("escNumber", options[:esc_no]) if options[:account_class] == "SOCIAL SERVICE"
    select("clinicCode", options[:department_code]) if options[:account_class] == "SOCIAL SERVICE"
    click "//input[@value='Submit Changes']", :wait_for => :page
    return get_text("errorMsg") if is_element_present("errorMsg")
    return get_text("successMessages")
  end
  def ss_document_search(options={})
    click "link=View and Reprinting"
    sleep 2
    click "link=#{options[:select]}", :wait_for => :page
    if options[:search_option] == "DOCUMENT DATE"
      select_button = (is_element_present "searchOptions") ? "searchOptions" :  "searchOption"
      select select_button, "label=#{options[:search_option]}"
      type "dateSearchEntry", options[:entry] if options[:entry]
    else
    #  select "//select[@id='documentType']", "label=#{options[:doc_type]}" if options[:doc_type]
      select "id=searchOptions", "label=#{options[:search_option]}" if options[:search_option]


     # select "searchOption", "label=#{options[:search_option]}" if options[:search_option]
      type "textSearchEntry", options[:entry] if options[:entry] && (is_element_present("textSearchEntry"))
      sleep 2
    end
    click "actionButton", :wait_for => :page
    return get_text("css=#processedDiscountsBody>tr").include? "Reprint Prooflist" if options[:select] == "Discount"
    return get_text("css=#row>tbody>tr").include? "Reprint PhilHealth Form" if options[:select] == "PhilHealth"
    return get_text('css=table[id="orSearchResults"]').include? "Re-print OR" if options[:doc_type] == "OFFICIAL RECEIPT"
    return get_text('css=table[id="orSearchResults"]').include? "Reprint Prooflist" if options[:doc_type] == "DISCOUNT"
 #  return get_text('css=table[id="orSearchResults"]').include? "Re-print OR" if options[:select] == "Payment"
   return get_text("//html/body/div/div[2]/div[2]/div[6]/table/tbody/tr/td[7]/div/a").include? "Re-print OR" if options[:select] == "Payment" #and options[:search_option] == "DOCUMENT NUMBER"
  end
end
