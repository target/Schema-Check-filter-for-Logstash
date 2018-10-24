# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/schema_check"

describe LogStash::Filters::SchemaCheck do

  context 'Inline Schema' do
    describe "Test schema provided inline" do
      config <<-CONFIG
        filter {
          schema_check {
            schema => '{"type":"object","properties":{"ip_address":{"oneOf":[{"format":"ipv4","type":"string"},{"format":"ipv6","type":"string"}]}}}'
          }
        }
      CONFIG

      sample("ip_address" => "I_AM_NOT_AN_IP") do
        insist { subject.get("tags") } == ["_schemacheckfailure"]
      end
      sample("ip_address" => "10.0.0.1") do
        insist { subject.get("tags") } != ["_schemacheckfailure"]
      end
    end

    describe "Test schema debug functionality inline" do
      config <<-CONFIG
        filter {
          schema_check {
            schema => '{"type":"object","properties":{"ip_address":{"oneOf":[{"format":"ipv4","type":"string"},{"format":"ipv6","type":"string"}]}}}'
            debug_output => true
          }
        }
      CONFIG

      sample("ip_address" => "I_AM_NOT_AN_IP") do
        insist { subject.get("tags") } == ["_schemacheckfailure"]
        insist { subject.get("schema_errors").to be(Array) }
      end
      sample("ip_address" => "10.0.0.1") do
        insist { subject.get("tags") } != ["_schemacheckfailure"]
      end
    end
  end

  context  "File Schema" do
    schema_file = File.join(File.dirname(__FILE__), "..", "fixtures", "test.json")
    describe "Test schema provided from file" do
      config <<-CONFIG
        filter {
          schema_check {
            "schema_path" => "#{schema_file}"
          }
        }
      CONFIG

      sample("ip_address" => "I_AM_NOT_AN_IP") do
        insist { subject.get("tags") } == ["_schemacheckfailure"]
      end
      sample("ip_address" => "10.0.0.1") do
        insist { subject.get("tags") } != ["_schemacheckfailure"]
      end
    end
  end
end
