#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module ClinicalAlerts

  def go_to_arms_das_technologist
    #click "//a[contains(@href, '/mainMenu.html')]", :wait_for => :page
    click "link=Home", :wait_for => :page
    click "link=ARMS DAS Technologist", :wait_for => :page
    #click "link=ARMS DAS Technologist", :wait_for => :page
  end
  def go_to_arms_dastect_package
     #click "//a[contains(@href, '/mainMenu.html')]", :wait_for => :page
     sleep 2
    click "link=Home", :wait_for => :page
    sleep 3
    click "link=ARMS DAS Technologist", :wait_for => :page
    #click "link=ARMS DAS Technologist", :wait_for => :page
    sleep 5
  end
  def das_tech_landing_page(page)
    title = get_title
    assert = title.include? page
    if(assert)
      return true
    else return page
    end
  end
  def dastech_search(options = {})
    sleep 5
    type "//input[@id='pinLastName']", options[:criteria]
    sleep 3
    #type "//input[@id='pinLastName']", options[:criteria]
    if options[:more_options]
      click "slide-fade"
      sleep 4
      type "requestStartDate", options[:req_date_start] if options[:req_date_start]
      type "requestEndDate", options[:req_date_end] if options[:req_date_end]
      type "scheduleStartDate", options[:sched_date_start] if options[:sched_date_start]
      type "scheduleEndDate", options[:sched_date_end] if options[:sched_date_end]
      type "ciNumber", options[:ci_no] if options[:ci_no]
      sleep 4
      type "specimenNumber", options[:speci_no]
      type "itemCode", options[:item_code] if options[:item_code]
      sleep 4
      select "documentStatus", options[:doc_status] if options[:doc_status]
      select "orderStatus", options[:order_status] if options[:order_status]
    end
    sleep 4
    click "//input[@value='Search']", :wait_for => :page
    sleep 6
  end
  def dastech_search_checking
    pat_infos = ""
    #pat_infos = get_text("//table[@id='results']/tbody/tr/td[4]")
    sleep 3
    pat_infos = is_element_present("//table[@id='results']/tbody/tr/td[4]")
    #pat_infos = get_text("//table[@id='results']/tbody/tr/td[4]")
    if(pat_infos != "")
      return true
    else return pat_infos
    end
  end
  def go_to_result_data_entry_page
    click "link=Results Data Entry", :wait_for => :page
#    click "//table[@id='results']/tbody/tr[2]/td[11]/div/a", :wait_for => :page
    sleep 4
  end
  def dastech_outpatient_get_ci_no(options = {})
    a = options[:pin]
   conn = OCI8.new('MDPQASAPROD','mdpqasaprod','192.168.137.29:1521/hcsdb')
    ci_no = conn.exec("select a.CI_NO from SLMCQASAPROD.TXN_OM_ORDER_GRP a INNER JOIN SLMCQASAPROD.TXN_OM_ORDER_DTL b ON a.ORDER_GRP_NO = b.ORDER_GRP_NO JOIN SLMCQASAPROD.TXN_ADM_ENCOUNTER c ON a.VISIT_NO = c.VISIT_NO WHERE c.PIN ='#{a}'")
     b = ci_no.fetch
     puts("VALUE = #{b[0]}")
     ci_no = b[0]
      if ci_no !nil
        return ci_no
      else  return false
      end

  end
  def dastech_get_ci_no
    click "//div[@id='grpOrders']/ul/li[3]/a/span"
    sleep 4
    #return get_text("//html/body/div/div[2]/div[2]/div[5]/div[3]/table/tbody/tr/td[2]")
    return get_text("//html/body/div/div[2]/div[2]/div[5]/div/div/div[3]/table/tbody/tr/td[2]")
  end
  def dastech_get_ci_package_item1
    click "//div[@id='grpOrders']/ul/li[3]/a/span"
    sleep 4
    return get_text("//html/body/div/div[2]/div[2]/div[5]/div[3]/table/tbody/tr/td[2]")
  end
  def dastech_get_ci_package_item2
    click "//div[@id='grpOrders']/ul/li[3]/a/span"
    sleep 4
    return get_text("//html/body/div/div[2]/div[2]/div[5]/div[3]/table/tbody/tr[3]/td[2]")
  end
  def dastech_get_ci_package_item3
    click "//div[@id='grpOrders']/ul/li[3]/a/span"
    sleep 4
    return get_text("//html/body/div/div[2]/div[2]/div[5]/div[3]/table/tbody/tr[5]/td[2]")
  end
  def dastech_get_ci_package_item4
    click "//div[@id='grpOrders']/ul/li[3]/a/span"
    sleep 4
    return get_text("//html/body/div/div[2]/div[2]/div[5]/div[3]/table/tbody/tr[7]/td[2]")
  end
  def dastech_result_data_entry(options = {})
    #IDDLD#
    type "name=PARAM::#{options[:testno]}::INDICATION", options[:indication] if options[:indication]
    sleep 4
    type "name=PARAM::#{options[:testno]}::HISTORY", options[:history] if options[:history]
    sleep 4
    type "name=PARAM::#{options[:testno]}::MEDICATION", options[:medication] if options[:medication]
    sleep 4
    type "name=PARAM::#{options[:testno]}::ENDOSCOPICFINDINGS", options[:endofindings] if options[:endofindings]
    sleep 4
    type "name=PARAM::#{options[:testno]}::ENDOSONOGRAPHICFINDINGS", options[:endosfindings] if options[:endosfindings]
    sleep 4
    type "name=PARAM::#{options[:testno]}::DIAGNOSIS", options[:diagnosis] if options[:diagnosis]
    sleep 4
    type "name=PARAM::#{options[:testno]}::RECOMMENDATION", options[:recomendation] if options[:recomendation]
    sleep 4

    #X-RAY#
    type "name=PARAM::#{options[:testno8]}::EXAMINATION_VALUE", options[:exam_val] if options[:exam_val] #006600000000001
    sleep 4
    type "name=PARAM::#{options[:testno8]}::HISTORES", options[:history2] if options[:history2]
    sleep 4
    type "name=PARAM::#{options[:testno8]}::COMPARES", options[:compare] if options[:compare]
    sleep 4
    type "name=PARAM::#{options[:testno8]}::TECHNIQUERES", options[:technique] if options[:technique]
    sleep 4
    type "name=PARAM::#{options[:testno8]}::FINDRES", options[:findres] if options[:findres]
    sleep 4
    type "name=PARAM::#{options[:testno8]}::IMPRESRES", options[:impress] if options[:impress]
    sleep 4
    type "name=PARAM::#{options[:testno8]}::REMARKSRES", options[:remarks] if options[:remarks]
    sleep 4

    if options[:sig1]
      click "//img[@alt='Search']"
      sleep 4
      type "sf1_entity_finder_key", options[:sig1]
      click "//input[@value='Search']"
      sleep 5
      click "link=#{options[:sig1]}"
      sleep 3
    end
    if options[:sig2]
      click "//form[@id='resultDataEntryBean']/div[14]/span[4]/a/img"
      sleep 4
      type "sf2_entity_finder_key", options[:sig2]
      click "xpath=(//input[@value='Search'])[2]"
      #click "//input[@value='Search']"
      #click "//inputX[@value='Search' and @type='button' and @onclick='DSF2.search();']"
      sleep 5
      click "//tbody[@id='sf2_finder_table_body']/tr/td/a"
#     click "//a[@onclick=\"DSF2.selectThis('#{options[:sig2]}');return false;\"]"
      sleep 3
    end
   click "//input[@value='Save']", :wait_for => :page
    #click "//input[@value='Save' and @type='Button' and @onclick=\"validateAndSubmit('a_save');\"]", :wait_for => :page if options[:save]
   sleep 6
   click "//input[@name='a_queue1']", :wait_for => :page
   sleep 4
   #click "//input[@name='a_validate1']"
#    type "//input[@id='validatePassword']", options[:password1]
#    click "//input[@value='Submit']"
#    clcik "//input[@name='a_official1']"
#    type "//input[@id='validatePassword']", options[:password2]
#    click "//input[@value='Submit']"
#    click "//form[@id='resultDataEntryBean']/div[5]/span/input[2]", :wait_for => :page if options[:update]
  end
  def dasmicro_result_data_entry(options = {})
    sleep 3
    type "name=PARAM::006200000000044::UNIT",options[:label1] if options[:label1] #006200000000039
    sleep 4
    type "name=PARAM::006200000000045::UNIT",options[:unit1] if options[:unit1]
    sleep 4
    type "name=PARAM::006200000000046::UNIT",options[:label2] if options[:label2]
    sleep 5
#    select "//select[@name='PARAM::006200000000044::RESULT']", options[:label1]
#    sleep 2
#    type "//input[@name='PARAM::006200000000044::UNIT']", options[:unit1] if options[:unit1]
#    sleep 3
#    select "//select[@name='PARAM::006200000000045::RESULT']", options[:label2]
#    sleep 2
#    type "//input[@name='PARAM::006200000000045::UNIT']", options[:unit2] if options[:unit2]
#    sleep 3
#    select "//select[@name='PARAM::006200000000046::RESULT']", options[:label3]
#    sleep 2
#    type "//input[@name='PARAM::006200000000046::UNIT']", options[:unit3] if options[:unit3]
#    sleep 2
#    type "//input[@name='PARAM::006200000000130::']", options[:microanalysis] if options[:microanalysis]
#    sleep 2
#    type "xpath=(//input[@name='PARAM::006200000000130::'])[2]", options[:unit4] if options[:unit4]
#    sleep 3
    
    if options[:sig1]
      click "//img[@alt='Search']"
      sleep 4
      type "sf1_entity_finder_key", options[:sig1]
      click "//input[@value='Search']"
      sleep 5
      click "link=#{options[:sig1]}"
      sleep 3
    end
    if options[:sig2]
      click "//form[@id='resultDataEntryBean']/div[14]/span[4]/a/img"
      sleep 4
      type "sf2_entity_finder_key", options[:sig2]
      click "xpath=(//input[@value='Search'])[2]"
      sleep 5
      click "//tbody[@id='sf2_finder_table_body']/tr/td/a"
   sleep 5
    end
   click "//input[@value='Save']", :wait_for => :page
    #click "//input[@value='Save' and @type='Button' and @onclick=\"validateAndSubmit('a_save');\"]", :wait_for => :page if options[:save]
   sleep 5
   click "//input[@name='a_queue1']", :wait_for => :page
   sleep 5
  end
  def dasmicro_result_data_entryqc(options = {})
    sleep 3
    select "//select[@name='PARAM::006200000000044::RESULT']", options[:label1]
    sleep 2
    type "//input[@name='PARAM::006200000000044::UNIT']", options[:unit1] if options[:unit1]
    sleep 3
    select "//select[@name='PARAM::006200000000045::RESULT']", options[:label2]
    sleep 2
    type "//input[@name='PARAM::006200000000045::UNIT']", options[:unit2] if options[:unit2]
    sleep 3
    select "//select[@name='PARAM::006200000000046::RESULT']", options[:label3]
    sleep 2
    type "//input[@name='PARAM::006200000000046::UNIT']", options[:unit3] if options[:unit3]
#    sleep 2
#    type "//input[@name='PARAM::006200000000130::']", options[:microanalysis] if options[:microanalysis]
#    sleep 2
#    type "xpath=(//input[@name='PARAM::006200000000130::'])[2]", options[:unit4] if options[:unit4]
    sleep 3

    if options[:sig1]
      click "//img[@alt='Search']"
      sleep 4
      type "sf1_entity_finder_key", options[:sig1]
      click "//input[@value='Search']"
      sleep 5
      click "link=#{options[:sig1]}"
      sleep 3
    end
    if options[:sig2]
      click "//form[@id='resultDataEntryBean']/div[14]/span[4]/a/img"
      sleep 4
      type "sf2_entity_finder_key", options[:sig2]
      click "xpath=(//input[@value='Search'])[2]"
      sleep 5
      click "//tbody[@id='sf2_finder_table_body']/tr/td/a"
   sleep 5
    end
   click "//input[@value='Save']", :wait_for => :page
    #click "//input[@value='Save' and @type='Button' and @onclick=\"validateAndSubmit('a_save');\"]", :wait_for => :page if options[:save]
   sleep 5
   click "//input[@name='a_queue1']", :wait_for => :page
   sleep 6

    click "//input[@name='a_validate1']"
    sleep 5
    type "//input[@id='validateUsername']", "ralopez"
    sleep 5
    type "//input[@id='validatePassword']", "ralopez"
    sleep 3
    click "//input[@value='Submit']"
    sleep 5
    click "//input[@name='a_official1']"
    sleep 2
    type "//input[@id='validateUsername']", "ralopez"
    sleep 5
    type "//input[@id='validatePassword']", "ralopez"
    sleep 5
    click "//input[@value='Submit']", :wait_for => :page
    sleep 5
    doc_status = get_text("//html/body/div/div[2]/div[2]/form/div[3]/span[3]")
    if(doc_status == "OFFICIAL")
      return true
    else return "Data entry not tag as official. #{doc_status}"
    end
  end
  def dasurine_result_data_entry(options = {})
    type "name=PARAM::006200000000039::",options[:field1] if options[:field1] #006200000000039
    sleep 4
    type "xpath=(//input[@name='PARAM::006200000000039::'])[2]",options[:field2] if options[:field2]
    sleep 4
    type "xpath=(//input[@name='PARAM::006200000000039::'])[3]",options[:field3] if options[:field3]
    sleep 5

#    type "name=PARAM::#{options[:testno6]}::",options[:field1] if options[:field1] #006200000000039
#    sleep 4
#    type "xpath=(//input[@name='PARAM::#{options[:testno6]}::'])[2]",options[:field2] if options[:field2]
#    sleep 4
#    type "xpath=(//input[@name='PARAM::#{options[:testno6]}::'])[3]",options[:field3] if options[:field3]
#    sleep 4
#    type "xpath=(//input[@name='PARAM::#{options[:testno5]}::'])[3]",options[:color1] if options[:color1]
#    sleep 4
#    type "name=PARAM::#{options[:testno7]}::UNIT",options[:unit_col1] if options[:unit_col1] #006200000000002
#    sleep 4
#    type "name=PARAM::#{options[:testno7]}::NORMALVAL",options[:normalval] if options[:normalval]
#    sleep 4
#    #type "name=COMMON_PARAM::TRU::REMARKS", options[:remarks] if options[:remarks]
#    sleep 5

    if options[:sig1]
      click "//img[@alt='Search']"
      sleep 4
      type "sf1_entity_finder_key", options[:sig1]
      click "//input[@value='Search']"
      sleep 5
      click "link=#{options[:sig1]}"
      sleep 3
    end
    if options[:sig2]
      click "//form[@id='resultDataEntryBean']/div[14]/span[4]/a/img"
      sleep 4
      type "sf2_entity_finder_key", options[:sig2]
      click "xpath=(//input[@value='Search'])[2]"
      sleep 5
      click "//tbody[@id='sf2_finder_table_body']/tr/td/a"
      sleep 3
    end
      sleep 5
    click "//input[@value='Save']", :wait_for => :page#, :wait_for => :page if options[:save]
    #click "//input[@value='Save' and @type='Button' and @onclick=\"validateAndSubmit('a_save');\"]", :wait_for => :page if options[:save]
      sleep 5
    click "//input[@name='a_queue1']", :wait_for => :page
    type "name=PARAM::006200000000039::",options[:field1] if options[:field1] #006200000000039
    sleep 4
    type "xpath=(//input[@name='PARAM::006200000000039::'])[2]",options[:field2] if options[:field2]
    sleep 4
    type "xpath=(//input[@name='PARAM::006200000000039::'])[3]",options[:field3] if options[:field3]
    sleep 5
    end
  def dasurine_result_data_entryqc(options = {})
    type "name=PARAM::#{options[:testno6]}::",options[:field1] if options[:field1] #006200000000039
    sleep 4
    type "xpath=(//input[@name='PARAM::#{options[:testno6]}::'])[2]",options[:field2] if options[:field2]
    sleep 4
    type "xpath=(//input[@name='PARAM::#{options[:testno6]}::'])[3]",options[:field3] if options[:field3]
    sleep 4
    type "xpath=(//input[@name='PARAM::#{options[:testno5]}::'])[3]",options[:color1] if options[:color1]
    sleep 4
    type "name=PARAM::#{options[:testno7]}::UNIT",options[:unit_col1] if options[:unit_col1] #006200000000002
    sleep 4
    type "name=PARAM::#{options[:testno7]}::NORMALVAL",options[:normalval] if options[:normalval]
    sleep 4
    #type "name=COMMON_PARAM::TRU::REMARKS", options[:remarks] if options[:remarks]
    sleep 5

    if options[:sig1]
      click "//img[@alt='Search']"
      sleep 4
      type "sf1_entity_finder_key", options[:sig1]
      click "//input[@value='Search']"
      sleep 5
      click "link=#{options[:sig1]}"
      sleep 4
    end
    if options[:sig2]
      click "//form[@id='resultDataEntryBean']/div[14]/span[4]/a/img"
      sleep 4
      type "sf2_entity_finder_key", options[:sig2]
      click "xpath=(//input[@value='Search'])[2]"
      sleep 5
      click "//tbody[@id='sf2_finder_table_body']/tr/td/a"
      sleep 3
    end
      sleep 5
   click "//input[@value='Save']", :wait_for => :page#, :wait_for => :page if options[:save]
    #click "//input[@value='Save' and @type='Button' and @onclick=\"validateAndSubmit('a_save');\"]", :wait_for => :page if options[:save]
      sleep 5
   click "//input[@name='a_queue1']", :wait_for => :page
      sleep 5
    type "name=PARAM::#{options[:testno6]}::",options[:fielda] if options[:fielda] #006200000000039
    sleep 4
    type "xpath=(//input[@name='PARAM::#{options[:testno6]}::'])[2]",options[:fieldb] if options[:fieldb]
    sleep 4
    type "xpath=(//input[@name='PARAM::#{options[:testno6]}::'])[3]",options[:fieldc] if options[:fieldc]
    sleep 4
    type "xpath=(//input[@name='PARAM::#{options[:testno5]}::'])[3]",options[:colord] if options[:colord]
    sleep 5
    click "//input[@name='a_validate1']"
    sleep 5
    type "//input[@id='validateUsername']", "ralopez"
    sleep 5
    type "//input[@id='validatePassword']", "ralopez"
    sleep 5
    click "//input[@value='Submit']"
    sleep 8
    type "name=PARAM::#{options[:testno6]}::",options[:fielda] if options[:fielda] #006200000000039
    sleep 5
    type "xpath=(//input[@name='PARAM::#{options[:testno6]}::'])[2]",options[:fieldb] if options[:fieldb]
    sleep 4
    type "xpath=(//input[@name='PARAM::#{options[:testno6]}::'])[3]",options[:fieldc] if options[:fieldc]
    sleep 4
    type "xpath=(//input[@name='PARAM::#{options[:testno5]}::'])[3]",options[:colord] if options[:colord]
    sleep 5
    click "//input[@name='a_official1']"
    sleep 5
    type "//input[@id='validateUsername']", "ralopez"
    sleep 5
    type "//input[@id='validatePassword']", "ralopez"
    sleep 5
    click "//input[@value='Submit']", :wait_for => :page
    sleep 5
    doc_status = get_text("//html/body/div/div[2]/div[2]/form/div[3]/span[3]")
    if(doc_status == "OFFICIAL")
      return true
    else return "Data entry not tag as official. #{doc_status}"
    end
  end
  def dascbc_result_data_entry(options = {})
    sleep 3
    click "name=COMMON_PARAM::TRUN::SPECIMEN", options [:specimen]
    sleep 5
    type "name=PARAM::#{options[:testno9]}::RESULT",options[:result1] if options[:result1] #005800000000026
    sleep 5
#    select "name=PARAM::#{options[:testno9]}::MACHINE", options [:machine]  if options[:normalval2]
#    sleep 5
    type "name=PARAM::#{options[:testno9]}::NORMALVAL",options[:normalval2] if options[:normalval2]
    sleep 3
#    type "name=PARAM::#{options[:testno9]}::RESULT",options[:result1] if options[:result1] #005800000000026
#    sleep 2
#    click "//select[@name='PARAM::005800000000026::MACHINE']", options [:machine]
#    sleep 5
#    type "name=PARAM::#{options[:testno9]}::NORMALVAL",options[:normalval2] if options[:normalval2]
#    sleep 2
#    type "name=PARAM::#{options[:testno10]}::RESULT",options[:result2] if options[:result2] #005800000000025
#    sleep 2
#    click "name=PARAM::005800000000025::MACHINE", options[:machine2]
#    sleep 5
#    type "name=PARAM::#{options[:testno10]}::NORMALVAL",options[:normalval3] if options[:normalval3]
#    sleep 5
#    click "name=COMMON_PARAM::TRUN::REMARKS"
#    sleep 2
    type "//textarea[@name='COMMON_PARAM::TRUN::REMARKS']", "MD PORTAL SELENIUM TEST"
#    sleep 4
#    click "name=COMMON_PARAM::TRUN::REMARKS"
    sleep 5

    if options[:sig1]
      click "//img[@alt='Search']"
      sleep 4
      type "sf1_entity_finder_key", options[:sig1]
      click "//input[@value='Search']"
      sleep 5
      click "link=#{options[:sig1]}"
      sleep 4
    end
    if options[:sig2]
      click "//form[@id='resultDataEntryBean']/div[14]/span[4]/a/img"
      sleep 5
      type "sf2_entity_finder_key", options[:sig2]
      click "xpath=(//input[@value='Search'])[2]"
      sleep 4
      click "//tbody[@id='sf2_finder_table_body']/tr/td/a"
   sleep 3
    end
   sleep 4
   click "//input[@value='Save']", :wait_for => :page
    #click "//input[@value='Save' and @type='Button' and @onclick=\"validateAndSubmit('a_save');\"]", :wait_for => :page if options[:save]
   sleep 5
   click "//input[@name='a_queue1']", :wait_for => :page
   sleep 5
   #click "//input[@name='a_validate1']"
  end
  def dastech_result_data_entry_checking
    sleep 3    
    if(is_element_present("//div[@id='successDiv']/div"))
      indication = is_element_present("//div[@id='rde_EUS']/div[3]/table/tbody/tr/td/label")
      history = is_element_present("//form[@id='resultDataEntryBean']/div[3]/span[3]")
      exam_date = is_element_present("examDate")
      subscript = is_element_present("//input[@value='Add Subscript']")
      superscript = is_element_present("//input[@value='Add Superscript']")
      reset = is_element_present("//input[@value='Reset Style']")
      if(file_no && doc_stat && exam_date && subscript && superscript && reset)
        return true
      else return "Missing elements in result page after saving RDE..."
      end
      return true
    else return "Error on saving RDE..."
    end
  end
  def data_entry_tag_as_official
    click "//form[@id='resultDataEntryBean']/div[5]/span/input[3]"
    sleep 4
    click "//form[@id='resultDataEntryBean']/div[5]/span/input[3]"
    sleep 4
    type "validateUsername", "dasdoc1"
    type "validatePassword", "123qweuser"
    click "//input[@value='Submit']"
    sleep 5
    click "//form[@id='resultDataEntryBean']/div[5]/span/input[3]"
    sleep 5
    click "//div[@id='divTemplatesSelectionPopup']/div[3]/button[1]"
    type "validateUsername", "dasdoc1"
    type "validatePassword", "123qweuser"
    click "//input[@value='Submit']", :wait_for => :page
    sleep 6
    doc_status = get_text("//form[@id='resultDataEntryBean']/div[3]/span[3]")
    if(doc_status == "OFFICIAL")
      return true
    else return "Data entry not tag as official. #{doc_status}"
    end
  end
  def data_entry_tag_as_officialqc
    click "//form[@id='resultDataEntryBean']/div[5]/span/input[3]"
    sleep 5
    click "//form[@id='resultDataEntryBean']/div[5]/span/input[3]"
    sleep 5
    type "validateUsername", "ralopez"
    type "validatePassword", "ralopez"
    click "//input[@value='Submit']"
    sleep 5
    click "//form[@id='resultDataEntryBean']/div[5]/span/input[3]"
    sleep 5
    click "//div[@id='divTemplatesSelectionPopup']/div[3]/button[1]"
    type "validateUsername", "ralopez"
    type "validatePassword", "ralopez"
    click "//input[@value='Submit']", :wait_for => :page
    sleep 6
    doc_status = get_text("//form[@id='resultDataEntryBean']/div[3]/span[3]")
    if(doc_status == "OFFICIAL")
      return true
    else return "Data entry not tag as official. #{doc_status}"
    end
  end
  def clinical_alerts_gu_verification
    pop_up = is_element_present("ui-dialog-title-divUnifiedAlerts")
    tab = is_element_present("link=Panic Values (1)")
    patient = is_element_present("aClinicAlertPat-1012000190")
    item = is_element_present("aClinicAlertPatProc-1012000190-005700000000045")
    if(pop_up && tab && patient && item)
      return true
    else return false
    end
  end
  def clinical_alerts_gu_dismiss(options = {})
    id = options[:id]
    click "imgClinicAlertProcPlus-1012000190"
    sleep 4
    click "aClinicAlertPatProc-1012000190-005700000000045"
    sleep 4
    click "lblClinicAlertDismiss-#{id}"
    sleep 4
    select "selClinicAlertActionTaken-#{id}", "CALLED THE DOCTOR"
    type "txtClinicAlertRemarks-#{id}", options[:remarks]
    type "txtClinicAlertUsername-#{id}", options[:username]
    type "txtClinicAlertPassword-#{id}", options[:password]
    click "btnClinicAlertDismiss-#{id}"
    sleep 5
    result = is_element_present("lblClinicAlertDismiss-#{id}")
    if(!result)
      return true
    else return result
    end
  end
  def tag_as_official_packageqc
    sleep 3
    click "//input[@name='a_validate1']"
    sleep 5
    type "//input[@id='validateUsername']", "ralopez"
    sleep 5
    type "//input[@id='validatePassword']", "ralopez"
    sleep 3
    click "//input[@value='Submit']"
    sleep 5
    click "//input[@name='a_official1']"
    sleep 5
    type "//input[@id='validateUsername']", "ralopez"
    sleep 5
    type "//input[@id='validatePassword']", "ralopez"
    sleep 5
    click "//input[@value='Submit']", :wait_for => :page
    sleep 5
    doc_status = get_text("//html/body/div/div[2]/div[2]/form/div[3]/span[3]")
    if(doc_status == "OFFICIAL")
      return true
    else return "Data entry not tag as official. #{doc_status}"
    end
  end
  def tag_as_official_package
    sleep 5
    click "//input[@name='a_validate1']"
    sleep 5
    type "//input[@id='validateUsername']", "dcvillanueva"
    sleep 5
    type "//input[@id='validatePassword']", "123qweuser"
    sleep 3
    click "//input[@value='Submit']", :wait_for => :page
    sleep 5
    click "//input[@name='a_official1']"
    sleep 4
    type "//input[@id='validateUsername']", "dasdoc4"
    sleep 5
    type "//input[@id='validatePassword']", "123qweuser"
    sleep 5
    click "//input[@value='Submit']", :wait_for => :page
    sleep 5
    doc_status = get_text("//html/body/div/div[2]/div[2]/form/div[3]/span[3]")
    if(doc_status == "OFFICIAL")
      return true
    else return "Data entry not tag as official. #{doc_status}"
    end
  end
end
