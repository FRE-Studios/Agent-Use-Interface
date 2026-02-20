#!/usr/bin/env ruby
# frozen_string_literal: true

require "rexml/document"
require "rexml/xpath"

SCHEMATRON_NS = "http://purl.oclc.org/dsdl/schematron"

def usage!
  warn "Usage: scripts/run-schematron.rb <schematron.sch> <document.xml>"
  exit 2
end

usage! unless ARGV.length == 2

schematron_path, xml_path = ARGV

begin
  schematron = REXML::Document.new(File.read(schematron_path))
  xml_doc = REXML::Document.new(File.read(xml_path))
rescue REXML::ParseException => e
  warn "XML parse error: #{e.message}"
  exit 1
end

sch_ns = { "sch" => SCHEMATRON_NS }
rule_ns = {}

REXML::XPath.match(schematron, "//sch:ns", sch_ns).each do |ns_decl|
  prefix = ns_decl.attributes["prefix"]
  uri = ns_decl.attributes["uri"]
  next if prefix.to_s.empty? || uri.to_s.empty?

  rule_ns[prefix] = uri
end

errors = []
reports = []

REXML::XPath.match(schematron, "//sch:pattern/sch:rule", sch_ns).each do |rule|
  context = rule.attributes["context"]
  begin
    context_nodes = REXML::XPath.match(xml_doc, context, rule_ns)
  rescue StandardError => e
    errors << "#{schematron_path}: invalid rule context `#{context}` (#{e.message})"
    next
  end

  REXML::XPath.match(rule, "sch:assert", sch_ns).each do |assertion|
    test = assertion.attributes["test"]
    message = assertion.text.to_s.gsub(/\s+/, " ").strip

    context_nodes.each do |node|
      begin
        passed = REXML::XPath.first(node, "boolean(#{test})", rule_ns)
      rescue StandardError => e
        errors << "#{schematron_path}: invalid assertion test `#{test}` (#{e.message})"
        break
      end
      next if passed

      errors << "#{xml_path}: Schematron assertion failed: #{message}"
    end
  end

  REXML::XPath.match(rule, "sch:report", sch_ns).each do |report|
    test = report.attributes["test"]
    message = report.text.to_s.gsub(/\s+/, " ").strip

    context_nodes.each do |node|
      begin
        passed = REXML::XPath.first(node, "boolean(#{test})", rule_ns)
      rescue StandardError => e
        errors << "#{schematron_path}: invalid report test `#{test}` (#{e.message})"
        break
      end
      next unless passed

      reports << "#{xml_path}: Schematron report fired: #{message}"
    end
  end
end

reports.each { |report| warn report }

if errors.empty?
  puts "#{xml_path}: Schematron validation passed"
  exit 0
end

errors.each { |error| warn error }
exit 1
