#!/bin/env ruby
# encoding: utf-8
module AdmissionHelper

  def self.range_rand(min,max)
    min + rand(max-min)
  end
  def self.generate_employee
    f = get_employee_from_csv
    d = f.readlines[self.range_rand(1, 1269)].split','
    {
      :emp_no => d[0],
      :last_name => d[1],
      :first_name => d[2],
      :middle_name => d[3],
      :gender => d[4],
      :birth_day => d[5],
      :emp_status => d[6],
      :hire_date => d[7],
    }
  end
  def self.generate_employee_dependent_based_on_employee_no(emp_no)
    i = 0
    t = ""
    while !(t.match emp_no)  do
      t = get_employee_dependent_from_csv.readlines[i]
      i += 1
    end
    i -= 1
    d =  get_employee_dependent_from_csv.readlines[i].split','
    {
      :benefactor_no => d[0],
      :last_name => d[1],
      :first_name => d[2],
      :middle_name => d[3],
      :birth_day => d[4],
      :emp_rel => d[5]
      #:qualified => d[7]
    }
  end
  def self.get_employee_dependent_from_csv
    File.new(File.dirname(__FILE__) +  '/../../../csv/employee_dependents.csv')
  end
  def self.get_employee_from_csv
    File.new(File.dirname(__FILE__) +  '/../../../csv/employees.csv')
  end
  def self.calculate_age(dob)
    unless dob.nil?
      a = Date.today.year - dob.year
      b = Date.new(Date.today.year, dob.month, dob.day)
      a = a-1 if b > Date.today
      return a
    end
    nil
  end
  def self.calculate_year_of_service(doh)
    unless doh.nil?
      doh = Date.strptime(doh,"%m/%d/%Y")
      a = Date.today.year - doh.year
      b = Date.new(Date.today.year, doh.month, doh.day)
      a = a-1 if b > Date.today
      return a
    end
  end
  def get_date_covered(options={})
    if options[:rb]
      days_to_adjust = options[:adjust_date]
      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
      set_date = (((d - days_to_adjust)).strftime("%m/%d/%Y").upcase).to_s
    else
      days_to_adjust = options[:adjust_date]
      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
      set_date = (((d - days_to_adjust)).strftime("%d-%b-%y").upcase).to_s
    end
    return set_date
  end
  def increase_date_by_one(t=0)
    if t != 0
      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
      back_date = (((d - t)).strftime("%d/%m/%Y").upcase).to_s

      initial = back_date.split('/')
      e = Date.strptime(initial[2] + "-" + initial[1] + "-" + initial[0])
      set_date = (((e + 1)).strftime("%d/%b/%y").upcase).to_s
    else
      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
      back_date = (((d - t)).strftime("%d/%m/%Y").upcase).to_s

      initial = back_date.split('/')
      e = Date.strptime(initial[2] + "-" + initial[1] + "-" + initial[0])
      set_date = (((e + 1)).strftime("%d/%b/%y").upcase).to_s
    end

    return set_date
  end
  def self.get_org_codes_info(location, org_code)
    if location == "GC"
      i = 0
      t = ""
      while !(t.match org_code)  do
        t = read_org_codes_gc.readlines[i]
        i += 1
      end
      i -= 1
      d =  read_org_codes_gc.readlines[i].split','
      {
        :location => d[0],
        :from => d[1],
        :description => d[2],
        :org_code => d[3],
      }

    elsif location == "QC"
      i = 0
      t = ""
      while !(t.match org_code)  do
        t = read_org_codes_qc.readlines[i]
        i += 1
      end
      i -= 1
      d =  read_org_codes_qc.readlines[i].split','
      {
        :location => d[0],
        :from => d[1],
        :description => d[2],
        :org_code => d[3],
      }
    end
  end
  def self.read_org_codes_gc
    File.new(File.dirname(__FILE__) +  '/../../../csv/org_codes_gc.csv')
  end
  def self.read_org_codes_qc
    File.new(File.dirname(__FILE__) +  '/../../../csv/org_codes_qc.csv')
  end
  def self.numerify(number_string)
        number_string.gsub(/#/) { rand(10).to_s }
      end
end
