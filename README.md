# Schema Check Filter for Logstash

* This is a plugin for [Logstash](https://github.com/elastic/logstash).
* This plugin have to be installed on top of the Logstash core pipeline. It is not a stand-alone program.

[![Target’s CFC-Open-Source Slack](https://cfc-slack-inv.herokuapp.com/badge.svg?colorA=155799&colorB=159953)](https://cfc-slack-inv.herokuapp.com/)


## Installing

This plugin is to be used with the Logstash system.  It is used to check whether an event is compliant with a provided schema.

## Installing plugin

```sh
bin/logstash-plugin install logstash-filter-schema_check
```

### Example Configuration
```ruby
input {
  stdin {}
}

filter {
  schema_check {
      schema_path => "test.json"

      }
    }
  }
}

```

### JSON Schema Example

```json
{
  "type": "object",
  "properties": {
    "message": {
      "oneOf":[
        {
          "format":"ipv4",
          "type":"string"
        },
        {
          "format":"ipv6",
          "type":"string"
        }
      ]
    }
  }
}
```

### Example run and output
`logstash -e 'input { stdin {} } filter { schema_check { schema_path => "test.json" } } output { stdout {} }'`

```ruby
ping
{
       "message" => "ping",
      "@version" => "1",
          "tags" => [
        [0] "schema_invalid"
    ],
    "@timestamp" => 2018-08-06T15:49:19.021Z
}
192.168.10.1
{
       "message" => "192.168.10.1",
      "@version" => "1",
          "tags" => [
        [0] "schema_valid"
    ],
    "@timestamp" => 2018-08-06T15:49:19.021Z
}

```

### Example run with debug and output
`logstash -e 'input { stdin {} } filter { schema_check { schema_path => "test.json" debug_output => true } } output { stdout {} }'`

```ruby
ping
{
          "message" => "ping",
    "schema_errors" => [
        [0] "The property '#/message' of type String did not match any of the required schemas. The schema specific errors were:\n\n- oneOf #0:\n    - The property '#/message' must be a valid IPv4 address\n- oneOf #1:\n    - The property '#/message' must be a valid IPv6 address"
    ],
       "@timestamp" => 2018-08-06T15:53:07.835Z,
         "@version" => "1"
}
```

## Configuration Parameters

### schema
This is schema provided by hash in the configuration instead of a separate file.
This isn't as recommended as schemas can get very large, very quickly.

### schema_path
Path to file with schema

### refresh_interval
Set refresh interval for reading json schema file for updates

### debug_output
Enable debug output.  This prints validation failures in an array under the
field schema_errors.


Logstash is a registered trademark of Elasticsearch BV.

