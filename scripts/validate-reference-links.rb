#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "rexml/document"
require "rexml/xpath"
require "uri"

AUI_NS = "https://agentuseinterface.org/schema/0.1"

def usage!
  warn "Usage: scripts/validate-reference-links.rb <catalog-aui.xml>"
  exit 2
end

usage! unless ARGV.length == 1

catalog_path = Pathname.new(ARGV[0]).expand_path
begin
  catalog = REXML::Document.new(File.read(catalog_path))
rescue REXML::ParseException => e
  warn "XML parse error: #{e.message}"
  exit 1
end
ns = { "a" => AUI_NS }

errors = []

REXML::XPath.match(catalog, "/a:aui/a:tasks/a:task[@href]", ns).each do |task|
  href = task.attributes["href"].to_s.strip
  task_id = task.attributes["id"].to_s.strip

  if href.empty?
    errors << "#{catalog_path}: task `#{task_id}` has empty href"
    next
  end

  begin
    uri = URI.parse(href)
  rescue URI::InvalidURIError => e
    errors << "#{catalog_path}: task `#{task_id}` has invalid href `#{href}` (#{e.message})"
    next
  end

  if uri.absolute?
    warn "#{catalog_path}: task `#{task_id}` uses absolute href `#{href}`; skipping local file id check"
    next
  end

  detail_path = catalog_path.dirname.join(href).cleanpath
  unless detail_path.file?
    errors << "#{catalog_path}: task `#{task_id}` references missing detail file `#{detail_path}`"
    next
  end

  begin
    detail = REXML::Document.new(File.read(detail_path))
  rescue REXML::ParseException => e
    errors << "#{detail_path}: XML parse error (#{e.message})"
    next
  end
  root = detail.root

  if root.nil?
    errors << "#{detail_path}:1: empty detail XML document"
    next
  end

  unless root.name == "aui-task" && root.namespace == AUI_NS
    errors << "#{detail_path}: detail file root must be `{#{AUI_NS}}aui-task`"
    next
  end

  detail_id = root.attributes["id"].to_s.strip
  if detail_id != task_id
    errors << "#{detail_path}: detail id `#{detail_id}` does not match catalog task id `#{task_id}`"
  end
end

if errors.empty?
  puts "#{catalog_path}: reference-detail link validation passed"
  exit 0
end

errors.each { |error| warn error }
exit 1
