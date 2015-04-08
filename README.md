# Hiera::Cloudformation

This backend for Hiera can retrieve information from:

* the outputs of a CloudFormation stack
* the metadata of a resource in a stack

## Installation

    gem install hiera-cloudformation

## Usage

Add the backend to the list of backends in hiera.yaml:

    ---
    :backends:
      - yaml
      - cloudformation

To provide the backend with an AWS access key, you can add the following configuration to the
`:cloudformation` section in hiera.yaml:

    :cloudformation:
      :access_key_id: Your_AWS_Access_Key_ID_Here
      :secret_access_key: Your_AWS_Secret_Access_Key_Here

The data fetched from the CloudFormation API will be cached. By default this is a process local cache
which is persisted for 60 seconds. You may also store cached data in a Redis server and optionally
make the data persistent by setting a cache_ttl of < 1. To configure for Redis add the following 
configuration to the `:cloudformation` section in hiera.yaml (`:redis_port` and `:redis_db` settings
are optional and will default to the values shown.

    :cloudformation:
      :redis_hostname: Your_Redis_Hostname_Or_IP_Address
      :redis_port: 6379
      :redis_db: 0
      :cache_ttl: -1

If you set the cache_ttl so that data is not expired from the cache you should have some other
mechanism to keep the cache updated and cleaned of old keys. One way is to have a process CloudFormation
SNS/SQS events and insert, update and delete keys from the cache as stacks events take place.

If you do not add these keys to your configuration file, the access keys will be looked up from
the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables, or from an IAM
instance role (if you are running Hiera on an EC2 instance with an IAM role assigned).

The AWS region to use can also be configured in the `:cloudformation` section of hiera.yaml.
You can also tell the backend to convert string literals "true", "false", "3.14", etc to Boolean
or Number types with the `:parse_metadata` configuration option; this may be useful as
CloudFormation will convert Booleans and Numbers in the template JSON metadata into Strings when
retrieved from a stack resource:

    :cloudformation:
      :region: 'us-west-1'
      :parse_metadata: true

To use this backend you also need to add entries to your "hierarchy" in your hiera.yaml file.
If you put an entry of this form in your hierarchy:

    cfstack/<stack name>/outputs

the backend will request the outputs of the stack named `<stack name>` and search for an output
named the same as the requested key. If an output named the same as the key is found, the backend
will return the value of that output (as a string).
If you put an entry of this form in your hierarchy:

    cfstack/<stack name>/resources/<logical resource ID>

the backend will request the JSON metadata of the logical resource identified by the given ID,
in the named stack, and look for a JSON object under the top-level key "hiera" in the metadata.
If a JSON object is present under the top-level key "hiera", the backend will search for the
requested key in that JSON object, and return the value of the key if present.

The recommended way of constructing your hierarchy so that Puppet-managed nodes can retrieve
data relating to the CloudFormation stack they're part of, is to create facts on the Puppet nodes
describing what CloudFormation stack they're part of and what logical resource ID corresponds to
their instance. Then, assuming you have two facts "cloudformation_stack" and "cloudformation_resource"
reported on your node, you can add these entries to the "hierarchy" in hiera.yaml:

    - cfstack/%{cloudformation_stack}/outputs
    - cfstack/%{cloudformation_stack}/resources/%{cloudformation_resource}

and Hiera will replace the `%{...}` placeholders with the value of the facts on the node, enabling
the node to look up information about the stack it "belongs" to.

For example, if this snippet is included in your CloudFormation template, and you include an entry

    cfstack/<stack name>/outputs

in your hierarchy, you can look up the key "example_key" in Hiera and get the value of the logical
resource identified by "AWSEC2Instance" (for example, this might be an EC2 instance, so Hiera
would return the instance ID)

    "Outputs" : {
      "example_key": {
        "Description" : "AWSEC2Instance is the logical resource ID of the instance that was created",
        "Value" : { "Ref": "AWSEC2Instance" }
      }
    }

As another example, if you define an EC2 instance with the following snippet in your CloudFormation
template, including some metadata:

    "Resources" : {
      "MyIAMKey" : {
        "Type" : "AWS::IAM::AccessKey",
        ...
      },
      "AWSEC2Instance" : {
        "Type" : "AWS::EC2::Instance",
        "Properties" : {
          ...
        },
        "Metadata" : {
          "hiera" : {
            "class::access_key_id": { "Ref": "MyIAMKey" },
            "class::secret_access_key": { "Fn::GetAtt" : [ "MyIAMKey" , "SecretAccessKey" ] }
          }
        }
      }
    }

and you include an entry:

    cfstack/<stack name>/resources/AWSEC2Instance

in your hierarchy, you can query hiera for the key "class::access_key_id" or "class::secret_access_key"
and retrieve the attributes of the "MyIAMKey" resource created by CloudFormation.


## Run tests

Requires ruby 1.9+ for minitest

```bash
rake test
```
