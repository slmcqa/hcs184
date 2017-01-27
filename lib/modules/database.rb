#!/bin/env ruby
# encoding: utf-8
require 'yaml'
DB = YAML.load_file File.dirname(__FILE__) + '/../../config.yml'


require 'oci8' if DB['db_type'] == 'oracle'
require 'mysql_api'  if DB['db_type'] == 'mysql'
require 'csv'
#require 'fastercsv'

module Database

  def self.connect
    db_host = DB['db_host']
    db_user_name = DB['db_user_name']
    db_pw = DB['db_pw']
    db_port = DB['db_port']
    db_sid = DB['db_sid']
    @db_type = DB['db_type']
    db_name = "//#{db_host}:#{db_port}/#{db_sid}"

    if @db_type == "oracle"
       @conn = OCI8.new(db_user_name, db_pw, db_name)
        #puts "\nConnecting to remote oracle database...\n"
    else
      @conn =  Mysql.real_connect(db_host, db_user_name, db_pw, db_sid)
      puts "\nConnecting to mysql database...\n"
    end

  end
  def self.logoff
    if @db_type == "oracle"
      @conn.logoff
    else
      @conn.close
    end
  end
  #returns the first record from db
  def self.select_statement(q)
    if @db_type == "oracle"
      result = @conn.exec(q)
      a = result.fetch
    else
      result = @conn.query(q)
      a = result.fetch_row
    end
    return a[0]
  end
  #returns the last record from db
  def self.select_last_statement(q)
 #   a =[]
    if @db_type == "oracle"
      result = @conn.exec(q)
      a = result.fetch
    else
      result = @conn.query(q)
      a = result.fetch_row
    end
    return a.last
  end
  def self.my_select_last_statement(q)
     result = @conn.exec(q)
     if result !=nil
      a = result.fetch
     else
       a ="null"
     end
    return a
  end
  def self.select_all_rows(q)
    arr = []
    @conn.exec(q) do |row|
        row.each do |column| arr << column.to_s end
    end
    return arr
  end
  def self.my_select_all_rows(q)
    arr = []
    result = @conn.exec(q)    
    if result !=nil
         @conn.exec(q) do |row|
          row.each do |column| arr << column.to_s end
    end
    return arr
    end
  end
  #returns all records from db with array
  def self.select_all_statement(q)
    if @db_type == "oracle"
      result = @conn.exec(q)
      a = result.fetch
    else
      result = @conn.query(q)
      a = result.fetch_row
    end
    return a
  end
  def self.update_statement(q)
    if @db_type == "oracle"
      @conn.exec(q)
      @conn.commit
    else
      @conn.query(q)
    end
  end
  def self.db_type
    @db_type
  end
  ##########################  MODULE-SPECIFIC METHODS BELOW ############################
  # Admission
  def get_number_of_free_rooms_using_orgcode_and_room_charge(org_code, room_charge)
#    if Database.db_type == "oracle"
#      if org_code == '0287'
#        q = "select cast(count(*) as integer) from REF_ROOM_BED where ORG_STRUCTURE = '0287' and ROOMNO <> 'N1017' and ROOMNO <> 'N1009' and ROOMNO <> 'N1012' and ROOMNO like '%XST%'"
#      else
#        q = "select cast(count(*) as integer) from REF_ROOM_BED where RB_STATUS = 'RBS01' and ORG_STRUCTURE = '#{org_code}' and ROOM_CHARGE = '#{room_charge}' and ROOMNO like '%XST%'"
#      end
#    else
#      q = "select count(*) from REF_ROOM_BED where RB_STATUS = 'RBS01' and ORG_STRUCTURE = '#{org_code}' and ROOM_CHARGE = '#{room_charge}'"
#    end
#    Database.select_statement q
  end
  def set_rooms_as_available_for_org_code(org_code)
        q = "update REF_ROOM_BED set RB_STATUS = 'RBS01' where ORG_STRUCTURE = '#{org_code}' and ROOMNO like '%XST%'"
        Database.update_statement q
  end
  def evaluate_rooms_for_admission(org_code, room_charge, minimum_count_of_free_rooms_before_setting_as_available = 0)
          Database.connect
          free_rooms = get_number_of_free_rooms_using_orgcode_and_room_charge(org_code, room_charge)
          if free_rooms ==  minimum_count_of_free_rooms_before_setting_as_available
            set_rooms_as_available_for_org_code(org_code)
            puts "\n *** Updating Rooms in Database... *** \nSetting RB_STATUS of #{org_code} to RBS01... \nDone.\n"
          end
          free_rooms = get_number_of_free_rooms_using_orgcode_and_room_charge(org_code, room_charge)
          puts "\n#{free_rooms} room(s) available for admission\n"
          Database.logoff
  end
  def get_visit_number_using_pin(pin)
    Database.connect
    if Database.db_type == "oracle"
      puts "cast - pin"
      q = "select cast(VISIT_NO as char(10)) from SLMC.TXN_ADM_ENCOUNTER where PIN = '#{pin}'"
      puts "q = #{q}"
    else
      q = "select VISIT_NO from SLMC.TXN_ADM_ENCOUNTER where PIN = '#{pin}'"
    end
    vn = Database.select_last_statement q
    puts "vn - #{vn}"
    Database.logoff
    #vn = (vn.to_s).to_i if vn.count == 1
    return vn # vn.max
  end
  def self.get_column_names(options={})
    q = "select column_name from user_tab_columns where table_name = '#{options[:table]}'"
    details = []
    statement = Database.select_all_rows q
    details.push statement
    return statement
  end
  # adjust admission date from TXN ADM ENCOUNTER
  def adjust_admission_date(options ={})
    if options[:days_to_adjust]
      days_to_adjust = options[:days_to_adjust]
      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
      my_set_date = ((d - days_to_adjust).strftime("%d-%b-%y").upcase).to_s
    end
    Database.connect
    if options[:set_date] # adjust date for specific date
      q = "update SLMC.TXN_ADM_ENCOUNTER set ADM_DATETIME = '#{options[:set_date]}' where PIN = '#{options[:pin]}'"
    elsif options[:with_discharge_date]
      q = "update SLMC.TXN_ADM_ENCOUNTER set ADM_DATETIME = '#{my_set_date}', CREATED_DATETIME = '#{my_set_date}' where PIN = '#{options[:pin]}'"
    else # adjust date based on days to adjust
      q = "update SLMC.TXN_ADM_ENCOUNTER set ADM_DATETIME = '#{my_set_date}', UPDATED_DATETIME = '#{Time.now.strftime('%d-%b-%y').upcase}' where PIN = '#{options[:pin]}' and VISIT_NO = '#{options[:visit_no]}'"
    end
    Database.update_statement q
    Database.logoff
    return my_set_date
  end
  # adjust ph_date_time from TXN_PBA_PH_HISTORY
  def adjust_ph_date(options ={})
    if options[:days_to_adjust]
      days_to_adjust = options[:days_to_adjust]
      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
      set_date = ((d - days_to_adjust).strftime("%d-%b-%y").upcase).to_s # even though it is incorect in the table, db converts it to correct format
    end
    Database.connect
    q = "update TXN_PBA_PH_HISTORY set PH_DATE_CLAIM = '#{set_date}' where VISIT_NO = '#{options[:visit_no]}'"
    Database.update_statement q
    Database.logoff
    return set_date
  end
  def adjust_adm_date_and_create_date_on_txn_pba_ph_hdr(options={})
    days_to_adjust = options[:days_to_adjust]
    d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
    set_date = (((d - days_to_adjust)).strftime("%d-%b-%y").upcase).to_s
    Database.connect
    q = "update TXN_PBA_PH_HDR set ADM_DATETIME = '#{set_date}', CREATED_DATETIME = '#{set_date}' where VISIT_NO = '#{options[:visit_no]}'"
    Database.update_statement q
    Database.logoff
  end
  def get_last_record_of_rb_trans_no(options={})
    Database.connect if options[:connect]
  #  q = "select RB_TRANS_NO from TXN_PBA_ROOM_BED_TRANS where RB_TRANS_NO = (select MAX(RB_TRANS_NO) from TXN_PBA_ROOM_BED_TRANS)"
   q = "select MAX(RB_TRANS_NO) + 1 FROM SLMC.TXN_PBA_ROOM_BED_TRANS WHERE RB_TRANS_NO NOT LIKE 'M%'"
    last_record = Database.select_last_statement q
    Database.logoff if options[:connect]
    last_record = last_record.to_i
    return last_record
  end
  def get_max_rb_trans_no_of_visit_no(visit_no)
    Database.connect
    q = "select RB_TRANS_NO from TXN_PBA_ROOM_BED_TRANS where VISIT_NO = '#{visit_no}'"
    #q = "select RB_TRANS_NO from TXN_PBA_ROOM_BED_TRANS where RB_TRANS_NO = (select MAX(RB_TRANS_NO) from TXN_PBA_ROOM_BED_TRANS)"
    rb = Database.select_statement q
    Database.logoff
    return rb
  end
  def insert_patient_to_doctor_dep(options)
      Database.connect if options[:connect]
      if options[:pin]
         q = "select BENEFACTOR_NO from SLMC.REF_DEPENDENT_OTHERS where LASTNAME in (select LASTNAME from SLMC.TXN_PATMAS where pin = '#{options[:pin]}')"
        sam =  Database.select_last_statement q
         if sam == nil
            benefactor_no =
            lastname = options[:lastname]
            firstname = options[:firstname]
            middlename =options[:middlename]
            birthdate = options[:birthdate]
            relationship = 'REL01'
            incapacitated ='N'
            qualified = 'Y'
            account_class = 'DRD'
            status = 'DRD'
            created_datetime = '2/10/2010'
            created_by = 'sandy'
            updated_datetime = '2/10/2010'
            updated_by = 'sandy'
                  t = "INSERT INTO TXN_PBA_DISC_DTL VALUES('#{benefactor_no}', '#{lastname}', '#{firstname}', '#{middlename}',
           '#{birthdate}', '#{relationship}', '#{incapacitated}', '#{qualified}', '#{account_class}', '#{status}',
           '#{created_datetime}', '#{created_by}', '#{updated_datetime}', '#{updated_by }')"
      Database.update_statement t
      Database.logoff if options[:connect]
         end
      end
end
  def insert_new_record_on_txn_pba_disc_dtl(options={})
    Database.connect if options[:connect]
    if options[:visit_no] == "false" || options[:visit_no] == false
      puts "Cannot Add to database, Visit Number is false"
      elsif options[:visit_no] != false || options[:visit_no] != "false"
        q = "select DISCOUNT_NO from TXN_PBA_DISC_DTL where DISCOUNT_NO = (select MAX(DISCOUNT_NO) from TXN_PBA_DISC_DTL)"
        s = "select ID from TXN_PBA_DISC_DTL where ID = (select MAX(ID) from TXN_PBA_DISC_DTL)"
      last_discount = Database.select_last_statement q
      last_id = Database.select_last_statement s

      discount_no = (last_discount[0..1] + (last_discount[2..14].to_i + 1).to_s)
      discount_scope_id = options[:discount_scope_id] || ""
      reference_no = options[:visit_no] # required
      discount_type = options[:discount_type] || ""
      discount_scheme = options[:discount_scheme] || ""
      discount_amount = options[:discount_amount] # required
      order_dtl_no = options[:order_dtl_no] ||"" #(last_order_dtl[0..2] + (last_order_dtl[3..15].to_i + 1).to_s)
      adj_can_no = options[:adj_can_co] || ""
      rb_trans_no = options[:rb_trans_no] #required
      cancel_reason = options[:cancel_reason] || ""
      late_flag = options[:late_flag] || "N"
      status = options[:status] || "A"
      created_datetime = options[:created_datetime] #required #(Time.now).strftime("%m/%d/%Y")
      created_by = options[:created_by] #required
      updated_datetime = options[:updated_datetime] || ""
      updated_by = options[:updated_by] || ""
      id = options[:id] || (last_id.to_i + 1).to_s
      disc_scope_id = options[:disc_scope_id] || ""
      discount_type_code = options[:discount_type_code] # required (0.16 promo C01) or (0.2 Senior C02)
      pos_order_dtl_no = options[:pos_order_dtl_no] || ""
      additional_package_flag = options[:additional_package_flag] || "N"
      print_tag = options[:print_tag] || ""
      partial_flag = options[:partial_flag] || "N"

      t = "INSERT INTO TXN_PBA_DISC_DTL VALUES('#{discount_no}', '#{discount_scope_id}', '#{reference_no}', '#{discount_type}',
           '#{discount_scheme}', '#{discount_amount}', '#{order_dtl_no}', '#{adj_can_no}', '#{rb_trans_no}', '#{cancel_reason}',
           '#{late_flag}', '#{status}', '#{created_datetime}', '#{created_by}', '#{updated_datetime}', '#{updated_by}', '#{id}',
           '#{disc_scope_id}', '#{discount_type_code}', '#{pos_order_dtl_no}', '#{additional_package_flag}', '#{print_tag}', '#{partial_flag}')"
      Database.update_statement t
      Database.logoff if options[:connect]
    end
  end
  def get_room_and_bed_no(options={})
    Database.connect
    q = "select ROOMNO,BEDNO from REF_ROOM_BED where ROOM_CHARGE = '#{options[:room_charge]}' and ORG_STRUCTURE='#{options[:org_code]}' and RB_STATUS = 'RBS01'"
    details = []
    record = Database.select_all_statement q
    Database.logoff
    details.push record
    return record
  end
  def edit_ph_date_claim(options={})
    days_to_adjust = options[:days_to_adjust]
    d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
    set_date = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s

    Database.connect
    q = "update TXN_PBA_PH_HISTORY set PH_DATE_CLAIM = '#{set_date}' where VISIT_NO = '#{options[:visit_no]}'"
    Database.update_statement q
    Database.logoff
  end
  def insert_new_record_on_txn_pba_room_bed_trans(options={})
    if options[:visit_no] == "false" || options[:visit_no] == false
      puts "Cannot Add to database, Visit Number is false"
    elsif options[:visit_no] != false || options[:visit_no] != "false"
      rb_trans_no = options[:rb_trans_no] ################ required
      visit_no = options[:visit_no] ###################### required
      date_covered = options[:date_covered] ############## required
      room_rate = options[:room_rate] || "4762" # current value in db is 4762
      nursing_unit = options[:nursing_unit] || "0278"
      room_charge = options[:room_charge] || "RCH07"
      room_no = options[:room_no] || "NR1601"
      bed_no = options[:bed_no] || "NB1601"
      rb_type = options[:rb_type] || "R"
      status = options[:status] || "A"
      cancel_reason = options[:cancel_reason] || "" # "sample cancel reason"
      created_by = options[:created_by] || ""
      created_datetime = options[:created_datetime] ############# required
      updated_by = options[:updated_by] || ""
      rooming_in = options[:rooming_in] || "N"
      updated_datetime = options[:updated_datetime] || ""
      late_flag = options[:late_flag] || ""
      Database.connect if options[:connect]
      q = "INSERT INTO TXN_PBA_ROOM_BED_TRANS VALUES('#{rb_trans_no}', '#{visit_no}', '#{date_covered}', '#{room_rate}', '#{nursing_unit}',
           '#{room_charge}', '#{room_no}', '#{bed_no}', '#{rb_type}', '#{status}', '#{cancel_reason}', '#{created_by}', '#{created_datetime}',
           '#{updated_by}', '#{rooming_in}', '#{updated_datetime}', '#{late_flag}')"
      Database.update_statement q
      Database.logoff if options[:connect]
    end
  end
  def get_or_number_using_pos_number(pos_number)
    Database.connect
    if Database.db_type == "oracle"
      q = "select cast(OR_NUMBER as char(20)) from TXN_PBA_PAYMENT_HDR where POS_NUMBER = '#{pos_number}'"
    else
      q = "select OR_NUMBER from TXN_PBA_PAYMENT_HDR where POS_NUMBER = '#{pos_number}'"
    end
    or_no = Database.select_last_statement q
    Database.logoff
    return or_no
  end
  def get_ci_number_using_pos_number(pos_number)
    Database.connect
    if Database.db_type == "oracle"
      q = "select cast(CI_NO as char(20)) from TXN_POS_ORDER_GRP where POS_NUMBER = '#{pos_number}'"
    else
      q = "select CI_NO from TXN_POS_ORDER_GRP where POS_NUMBER = '#{pos_number}'"
    end
    ci_no = Database.select_last_statement q
    Database.logoff
    return ci_no
  end
  def get_ord_grp_no_and_ci_no(visit_number,performing_unit)
    Database.connect
    q = "select ORDER_GRP_NO,CI_NO from TXN_OM_ORDER_GRP where VISIT_NO = '#{visit_number}' and PERFORMING_UNIT = '#{performing_unit}'"
    details = []
    record = Database.select_all_statement q

    details.push record
    puts "details - #{details}"
    puts "record - #{record}"
    Database.logoff
    return record
  end
  def get_discount_number_using_visit_number(options={})
    Database.connect
    if Database.db_type == "oracle"
      q = "select cast(DISCOUNT_NO as char(20)) from TXN_PBA_DISC_DTL where REFERENCE_NO = '#{options[:visit_no]}' and DISCOUNT_AMOUNT = '#{options[:discount_rate]}' and DISCOUNT_NO like '%M%'"
    else
      q = "select DISCOUNT_NO from TXN_PBA_DISC_DTL where REFERENCE_NO = '#{options[:visit_no]}' and DISCOUNT_AMOUNT='#{options[:discount_rate]}'"
    end
    disc_no = Database.select_statement q
 #   disc_no = Database.select_last_statement q
    Database.logoff
    puts "disc_no - #{disc_no}"
    return disc_no
  end
  def get_pin_number_based_on_name(options={})
    Database.connect
    if Database.db_type == "oracle"
      q = "select cast(PIN as char(10)) from TXN_PATMAS where LASTNAME = '#{options[:lastname]}' and FIRSTNAME = '#{options[:firstname]}'"
    else
      q = "select PIN from TXN_PATMAS where LASTNAME = '#{options[:lastname]}' and FIRSTNAME ='#{options[:firstname]}'"
    end
    pin_no = Database.select_last_statement q
    Database.logoff
    return pin_no
  end
  def get_item_rate(options={})
    #Database.connect # always connect first in database
    if options[:outpatient]
      q = "select RATE from REF_PC_SERVICE_RATE where ROOM_CLASS = 'RCL05' and SERVICE_CODE='SR#{options[:item_code]}'"
      w = "select MRP_TAG from REF_PC_SERVICE_RATE where ROOM_CLASS = 'RCL05' and SERVICE_CODE='SR#{options[:item_code]}'"
      r = "select PH_CODE from REF_PC_MASTER_SERVICE where MSERVICE_CODE='#{options[:item_code]}'"
      t = "select ORDER_TYPE from REF_PC_MASTER_SERVICE where MSERVICE_CODE='#{options[:item_code]}'"
      y = "select DESCRIPTION from REF_PC_MASTER_SERVICE where MSERVICE_CODE='#{options[:item_code]}'"
    elsif options[:inpatient]
      q = "select RATE from REF_PC_SERVICE_RATE where ROOM_CLASS = 'RCL02' and SERVICE_CODE='SR#{options[:item_code]}'"
      w = "select MRP_TAG from REF_PC_SERVICE_RATE where ROOM_CLASS = 'RCL02' and SERVICE_CODE='SR#{options[:item_code]}'"
      r = "select PH_CODE from REF_PC_MASTER_SERVICE where MSERVICE_CODE='#{options[:item_code]}'"
      t = "select ORDER_TYPE from REF_PC_MASTER_SERVICE where MSERVICE_CODE='#{options[:item_code]}'"
      y = "select DESCRIPTION from REF_PC_MASTER_SERVICE where MSERVICE_CODE='#{options[:item_code]}'"
    end
    info1 = (Database.select_last_statement q).to_f
    mrp = (Database.select_last_statement w).to_s
    ph_code = ((Database.select_last_statement r).to_s)
    ort_type = ((Database.select_last_statement t).to_s)
    desc = ((Database.select_last_statement y).to_s)
    puts "#{options[:item_code]},#{info1},#{mrp},#{ph_code},#{ort_type},#{desc}"
    my_data = ("#{options[:item_code]}" + "," + "#{info1}" + "," + "#{mrp}" + "," + "#{ph_code}" +  "," + "#{ort_type}" +  "," + "#{desc}").split(",")
    return my_data
  end
  def get_array_line_number(filename,order)
    my_file = CSV.read(filename)
    my_order = order
    x = 1
    my_file.each do
      my_order.each do
        if (my_file[x][0]) == (my_order)
          return x
        else
          if (x + 1) == my_file.count
          else
            x += 1
          end
        end
      end
    end
  end
  def delete_line_from_csv(filename,lines)
    line_arr = File.readlines(filename)
    line_arr.delete_at(lines)
    File.open(filename, "w") do |f|
      line_arr.each{|line| f.puts(line)}
    end
  end
  def add_line_to_csv(filename,order)
    jun = []
    line_arr = File.readlines(filename)
    File.open(filename, "w") do |f|
      line_arr.each{|line|f.puts(line)}
      jun << order.join(",")
      f.print(jun)
    end
  end
  def ss_get_discount_amount(options={})
    Database.connect
    if options[:promo]
      q = "select DISCOUNT_AMOUNT from TXN_PBA_DISC_DTL where REFERENCE_NO = '#{options[:visit_no]}' and (DISCOUNT_TYPE_CODE = 'C01' or DISCOUNT_TYPE_CODE = 'C02')"
      promo = Database.select_statement q
    end
    if options[:classification]
      q = "select DISCOUNT_AMOUNT from TXN_PBA_DISC_DTL where REFERENCE_NO = '#{options[:visit_no]}' and (DISCOUNT_SCHEME = 'SSEERA' or DISCOUNT_TYPE_CODE = 'C06')"
      classification = Database.select_statement q
    end
    if options[:fund_share]
      q = "select PCSO_SHARE from TXN_SS_RECOMMENDATION where VISIT_NO = '#{options[:visit_no]}'"
      fund_share = Database.select_statement q
    end
    if options[:ss_discount]
      q =  "select TXN_SS_COPAYOR.COVERAGE_AMOUNT
              from TXN_SS_RECOMMENDATION,TXN_SS_COPAYOR
              where (TXN_SS_RECOMMENDATION.SS_RECOMMENDATION_ID = TXN_SS_COPAYOR.SS_RECOMMENDATION_ID) and TXN_SS_RECOMMENDATION.VISIT_NO  = '#{options[:visit_no]}'"
      ss_discount = Database.select_statement q
    end
    if options[:social_service_discount_no]
      q = "select DISCOUNT_NO from TXN_PBA_DISC_DTL where REFERENCE_NO = '#{options[:visit_no]}' and (DISCOUNT_SCHEME = 'SSEERA' or DISCOUNT_TYPE_CODE = 'C06')"
      social_service_discount_no = Database.select_statement q
    end
    Database.logoff
    return promo.to_f if options[:promo]
    return classification.to_f  if options[:classification]
    return ss_discount.to_f  if options[:ss_discount]
    return social_service_discount_no  if options[:social_service_discount_no]
    return fund_share  if options[:fund_share]
  end
  def access_from_database(options={})
    Database.connect
    what = options[:what] || "cast(count(*) as integer)"
    if options[:all_info] # same as select *
      key = []
      statement = {}
      if options[:all_records]
        q = "select #{what} from #{options[:table]}"
      elsif options[:like]
        q = "select #{what} from #{options[:table]} where #{options[:column1].upcase} = '#{options[:condition1]}' #{options[:gate]} #{options[:column2].upcase} like '#{options[:condition2]}'"
      elsif options[:condition3]
        q = "select #{what} from #{options[:table]} where #{options[:column1].upcase} = '#{options[:condition1]}' #{options[:gate]} #{options[:column2].upcase} = '#{options[:condition2]}' #{options[:gate2]} #{options[:column3].upcase} = '#{options[:condition3]}'"
      elsif options[:condition2]
        q = "select #{what} from #{options[:table]} where #{options[:column1].upcase} = '#{options[:condition1]}' #{options[:gate]} #{options[:column2].upcase} = '#{options[:condition2]}'"
      elsif options[:condition1]
        q = "select #{what} from #{options[:table]} where #{options[:column1].upcase} = '#{options[:condition1]}'"
      end
      key = Database.get_column_names options
      record = Database.select_all_statement q
      (record.count).times do |r|
        if record[r].class == Time
          record[r] = record[r].strftime("%m/%d/%Y")
        end
      end
      key.each_with_index {|k,i|statement[k] = record[i]}
    else
      if options[:all_records]
        q = "select #{what} from #{options[:table]}"
      elsif options[:like]
        q = "select #{what} from #{options[:table]} where #{options[:column1].upcase} = '#{options[:condition1]}' #{options[:gate]} #{options[:column2].upcase} like '#{options[:condition2]}'"
      elsif options[:condition3]
        q = "select #{what} from #{options[:table]} where #{options[:column1].upcase} = '#{options[:condition1]}' #{options[:gate]} #{options[:column2].upcase} = '#{options[:condition2]}' #{options[:gate2]} #{options[:column3].upcase} = '#{options[:condition3]}'"
      elsif options[:condition2]
        q = "select #{what} from #{options[:table]} where #{options[:column1].upcase} = '#{options[:condition1]}' #{options[:gate]} #{options[:column2].upcase} = '#{options[:condition2]}'"
      elsif options[:condition1]
        q = "select #{what} from #{options[:table]} where #{options[:column1].upcase} = '#{options[:condition1]}'"
      end
      if options[:all_results]
        details = []
        statement1 = Database.select_all_rows q
        details.push statement
      else
        statement = Database.select_statement q
      end
    end
    Database.logoff
    return statement1 if options[:all_results]
    return statement
  end
  def update_from_database(options={})
    Database.connect
    q = "update #{options[:table]} set #{options[:what]} = '#{options[:set1]}' where #{options[:column1]} = '#{options[:condition1]}'"
    Database.update_statement q
    Database.logoff
  end
  def count_number_of_entries(options={})
    Database.connect
    what = options[:what] || "cast(count(*) as integer)"
    q = "SELECT  COUNT( #{what}) FROM (#{options[:table]}) WHERE (#{options[:column1].upcase} = '#{options[:condition1]}')"
    statement = Database.select_statement q
    Database.logoff
    return statement
  end
  def count_distinct_ci_number(options={})
    Database.connect
    q = "SELECT COUNT (CI_NO) FROM (TXN_OM_ORDER_GRP a), (TXN_OM_ORDER_DTL b)
            WHERE (A.ORDER_GRP_NO) = (B.ORDER_GRP_NO)
            AND (VISIT_NO = '#{options[:visit_no]}') AND (PACKAGE_TAG = 'N')"
    statement = Database.select_statement q
    Database.logoff
    return statement
  end
  def access_from_database_with_join(options={})#can accomodate 2 join
    Database.connect
    if options[:condition1]
      q = "SELECT * FROM #{options[:table1]}  T1 LEFT JOIN #{options[:table2]}  T2
           ON T1.#{options[:condition1]} = T2.#{options[:condition1]}
           WHERE #{options[:column1].upcase} = '#{options[:where_condition1]}' #{options[:gate]} #{options[:column2].upcase} = '#{options[:where_condition2]}'"
    elsif options[:condition2] && options[:gate]
      q = "SELECT * FROM #{options[:table1]}  T1 LEFT JOIN #{options[:table2]}  T2
           ON T1.#{options[:condition2]} = T2.#{options[:condition2]} LEFT JOIN #{options[:table3]} T3
           ON T1.#{options[:condition3]} = T3.#{options[:condition3]}
           WHERE #{options[:column1].upcase} = '#{options[:where_condition1]}' #{options[:gate]} #{options[:column2].upcase} = '#{options[:where_condition2]}'"
    else
      q = "SELECT * FROM #{options[:table1]}  T1 LEFT JOIN #{options[:table2]}  T2
           ON T1.#{options[:condition2]} = T2.#{options[:condition2]} LEFT JOIN #{options[:table3]} T3
           ON T1.#{options[:condition3]} = T3.#{options[:condition3]}
           WHERE #{options[:column1].upcase} = '#{options[:where_condition1]}'"
    end
    statement = Database.select_statement q
    Database.logoff
    return statement
  end
  def adjust_outpatient_date(options ={})
    if options[:days_to_adjust]
      days_to_adjust = options[:days_to_adjust]
      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
      my_set_date = ((d - days_to_adjust).strftime("%d-%b-%y").upcase).to_s
    end
    Database.connect
      q = "update #{options[:table]} set #{options[:table_column]} = '#{my_set_date}' where PIN = '#{options[:pin]}'"
    Database.update_statement q
    Database.logoff
    return my_set_date
  end
  def add_user_security(options={})
    user_id = access_from_database(:what => "ID", :table => "CTRL_APP_USER", :column1 => "USERNAME", :condition1 => options[:user])
    Database.connect
    created_by = options[:created_by] || "exist"
    updated_by = options[:updated_by] || ""
    updated_datetime = options[:updated_datetime] || ""
    dept_code = options[:dept_code] || ""
    q = "INSERT INTO REF_USER_SECURITY VALUES('#{rand(100000000)}', '#{user_id}',
    '#{options[:org_code]}', '#{options[:tran_type]}', '#{created_by}', 
    '#{Time.now.strftime("%d-%b-%y")}', '#{updated_by}', '#{updated_datetime}', '#{dept_code}')"
    Database.update_statement q
    Database.logoff
  end
  def get_case_rate(options={})
    rvs_code = options[:rvs_code]
    Database.connect
          rate  =  "SELECT RATE FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE = '#{rvs_code}' "
          case_rate = Database.select_statement rate
    Database.logoff
    return case_rate
  end
  def get_pf_rate(options={})
        rvs_code = options[:rvs_code]
        Database.connect
              pf  =  "SELECT PF_AMOUNT FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE = '#{rvs_code}' "
              pf_amount  = Database.select_statement pf
        Database.logoff
        return pf_amount
  end
  def self.get_sched_detail(options={})
        myrow  = options[:myrow]
        Database.connect
              a  = "SELECT * FROM SLMC.MY_SCHEDULER WHERE MYROW = '#{myrow}'"
              ary = Database.select_all_rows a
        Database.logoff
        return {
              :average_runtime => ary[0],
              :average_runtime_round => ary[1],
              :rake_command =>ary[2],
              :filename => ary[3],
              :set_time => ary[4],
              :mtime => ary[5],
              :mdate => ary[6],
              :dir => ary[7],
              :final_date => ary[8],
              :status => ary[9],
              :batch_filename => ary[10]
        }
  end
  def self.get_max_ci_no(options={})
            Database.connect
                   a = "SELECT ORGSTRUCTURE FROM SLMC.CTRL_APP_USER WHERE USERNAME = '#{options[:username]}'"
                   ary = Database.select_all_statement a
            Database.logoff
            xxxx  = ary[0]
            yyyy = Time.now.strftime("%Y")
            mm = Time.now.strftime("%m")
            xxxxyyyymm = xxxx +yyyy + mm
            Database.connect
                   a = "SELECT MAX(B.CI_NO) FROM SLMC.TXN_OM_ORDER_DTL A JOIN SLMC.TXN_OM_ORDER_GRP B ON A.ORDER_GRP_NO = B.ORDER_GRP_NO WHERE B.CI_NO LIKE '#{xxxxyyyymm}%'"
                   ary = Database.select_all_statement a
            Database.logoff
            ary[0].should != nil
            return {
                  :max_ci_no => ary[0]
             }
  end
  def self.get_details_my_ci(options={})
#          Database.connect
#                 a = "SELECT ORGSTRUCTURE FROM SLMC.CTRL_APP_USER WHERE USERNAME = '#{options[:username]}'"
#                 ary = Database.select_all_statement a
#          Database.logoff
#          xxxx  = ary[0]
#          yyyy = Time.now.strftime("%Y")
#          mm = Time.now.strftime("%m")
#          xxxxyyyymm = xxxx +yyyy + mm
          date = options[:date]
          org_code =   options[:org_code]
          ci = org_code + "2015"
          Database.connect
                 a = "SELECT CI_NO FROM SLMC.MY_CI_TABLE WHERE TRUNC(VALIDATE_DATETIME) >= TO_DATE('#{date}', 'MM/DD/YYYY')  AND PERFORMING_UNIT = '#{org_code}' AND CI_NO LIKE '#{ci}%'ORDER BY  CI_NO, VALIDATE_DATETIME ASC"
                 ary = Database.select_all_rows a
          Database.logoff
      #    ary[0].should != nil
          return {
                :ci_no => ary
           }
end
  def self.get_user_name()
     #   myrow  = options[:myrow]
       ary[]
        Database.connect
              a  = "SELECT EMPLOYEE,EMAIL,ORGSTRUCTURE FROM SLMC_CAS.CTRL_APP_USER  WHERE USERNAME <> 'casadmin'"
              ary = Database.select_all_rows a
        Database.logoff
       
        return {
              :employee_id => ary[0],
              :email => ary[1],
              :orgstructure =>ary[2]
        }
  end

end
