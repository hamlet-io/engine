[#ftl]
[#macro aws_input_shared_masterdata_seed ]
  [@addMasterData
    data=
{
  "Regions": {
    "ap-northeast-1": {
      "Partition": "aws",
      "Locality": "Tokyo",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "ap-northeast-1a"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "ap-northeast-1c"
        }
      },
      "Accounts": {
        "ELB": "582318560864"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-00d29e4cb217ae06b",
          "EC2": "ami-0ab3e16f9c414dee7",
          "ECS": "ami-0db78dede3fd15c0b"
        }
      }
    },
    "ap-northeast-2": {
      "Partition": "aws",
      "Locality": "Seoul",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "ap-northeast-2a"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "ap-northeast-2c"
        }
      },
      "Accounts": {
        "ELB": "600734575887"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-0d98591cbf9ef1ffd",
          "EC2": "ami-0e1e385b0a934254a",
          "ECS": "ami-0b9323e18f0848bbd"
        }
      }
    },
    "ap-south-1": {
      "Partition": "aws",
      "Locality": "Mumbai",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "ap-south-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "ap-south-1b"
        }
      },
      "Accounts": {
        "ELB": "718504428378"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-00b3aa8a93dd09c13",
          "EC2": "ami-02913db388613c3e1",
          "ECS": "ami-0fe00d4d7f42b9730"
        }
      }
    },
    "ap-southeast-1": {
      "Partition": "aws",
      "Locality": "Singapore",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "Index": 0,
          "AWSZone": "ap-southeast-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Singapore Zone B",
          "Index": 1,
          "AWSZone": "ap-southeast-1b"
        }
      },
      "Accounts": {
        "ELB": "114774131450"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-01514bb1776d5c018",
          "EC2": "ami-05c859630889c79c8",
          "ECS": "ami-07d16dcba5870e773"
        }
      }
    },
    "ap-southeast-2": {
      "Partition": "aws",
      "Locality": "Sydney",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "ap-southeast-2a",
          "NetworkEndpoints": [
            {
              "Type": "Interface",
              "ServiceName": "aws.sagemaker.ap-southeast-2.notebook"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.cloudformation"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.cloudtrail"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.codebuild"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.codepipeline"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.config"
            },
            {
              "Type": "Gateway",
              "ServiceName": "com.amazonaws.ap-southeast-2.dynamodb"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ec2"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ec2messages"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecr.api"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecr.dkr"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs-agent"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs-telemetry"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.elasticloadbalancing"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.events"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.execute-api"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.kinesis-streams"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.kms"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.logs"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.monitoring"
            },
            {
              "Type": "Gateway",
              "ServiceName": "com.amazonaws.ap-southeast-2.s3"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.sagemaker.api"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.sagemaker.runtime"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.secretsmanager"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.servicecatalog"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.sns"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.sqs"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ssm"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ssmmessages"
            }
          ]
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "ap-southeast-2b",
          "NetworkEndpoints": [
            {
              "ServiceName": "aws.sagemaker.ap-southeast-2.notebook",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.cloudformation",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.cloudtrail",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.codebuild",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.codepipeline",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.config",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.dynamodb",
              "Type": "Gateway"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ec2",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ec2messages",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ecr.api",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ecr.dkr",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs-agent",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs-telemetry",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.elasticloadbalancing",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.events",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.execute-api",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.kinesis-streams",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.kms",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.logs",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.monitoring",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.s3",
              "Type": "Gateway"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.sagemaker.api",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.sagemaker.runtime",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.secretsmanager",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.servicecatalog",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.sns",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.sqs",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ssm",
              "Type": "Interface"
            },
            {
              "ServiceName": "com.amazonaws.ap-southeast-2.ssmmessages",
              "Type": "Interface"
            }
          ]
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "ap-southeast-2c",
          "NetworkEndpoints": [
            {
              "Type": "Interface",
              "ServiceName": "aws.sagemaker.ap-southeast-2.notebook"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.cloudformation"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.cloudtrail"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.codebuild"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.codepipeline"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.config"
            },
            {
              "Type": "Gateway",
              "ServiceName": "com.amazonaws.ap-southeast-2.dynamodb"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ec2"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ec2messages"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecr.api"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecr.dkr"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs-agent"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ecs-telemetry"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.elasticloadbalancing"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.events"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.execute-api"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.kinesis-streams"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.kms"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.logs"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.monitoring"
            },
            {
              "Type": "Gateway",
              "ServiceName": "com.amazonaws.ap-southeast-2.s3"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.sagemaker.api"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.sagemaker.runtime"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.secretsmanager"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.servicecatalog"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.sns"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.sqs"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ssm"
            },
            {
              "Type": "Interface",
              "ServiceName": "com.amazonaws.ap-southeast-2.ssmmessages"
            }
          ]
        }
      },
      "Accounts": {
        "ELB": "783225319266"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-062c04ec46aecd204",
          "EC2": "ami-07cc15c3ba6f8e287",
          "ECS": "ami-00bf6a5319a7d03d4"
        }
      }
    },
    "ca-central-1": {
      "Partition": "aws",
      "Locality": "Central",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "ca-central-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "ca-central-1b"
        }
      },
      "Accounts": {
        "ELB": "985666609251"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-0b32354309da5bba5",
          "EC2": "ami-04070f04f450607dc",
          "ECS": "ami-05958d7635caa4d04"
        }
      }
    },
    "cn-north-1": {
      "Partition": "aws",
      "Locality": "Beijing",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "cn-north-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "cn-north-1b"
        }
      },
      "Accounts": {
        "ELB": "638102146993"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-0f944362",
          "EC2": "ami-dadb09b7"
        }
      }
    },
    "eu-central-1": {
      "Partition": "aws",
      "Locality": "Frankfurt",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "eu-central-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "eu-central-1b"
        }
      },
      "Accounts": {
        "ELB": "054676820928"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-06a5303d47fbd8c60",
          "EC2": "ami-010fae13a16763bb4",
          "ECS": "ami-0d3da340bcd9173b1"
        }
      }
    },
    "eu-west-1": {
      "Partition": "aws",
      "Locality": "Ireland",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "eu-west-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "eu-west-1b"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "eu-west-1c"
        }
      },
      "Accounts": {
        "ELB": "156460612806"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-024107e3e3217a248",
          "EC2": "ami-028188d9b49b32a80",
          "ECS": "ami-0f1670c2113013c34"
        }
      }
    },
    "eu-west-2": {
      "Partition": "aws",
      "Locality": "London",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "eu-west-2a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "eu-west-2b"
        }
      },
      "Accounts": {
        "ELB": "652711504416"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-0ca65a55561666293",
          "EC2": "ami-04de2b60dd25fbb2e",
          "ECS": "ami-0d9a6649bf66c98e7"
        }
      }
    },
    "eu-west-3": {
      "Partition": "aws",
      "Locality": "Paris",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "eu-west-3a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "eu-west-3b"
        }
      },
      "Accounts": {
        "ELB": "009996457667"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-0641e4dfc1427f114",
          "EC2": "ami-0652eb0db9b20aeaf",
          "ECS": "ami-08730c010a2285335"
        }
      }
    },
    "sa-east-1": {
      "Partition": "aws",
      "Locality": "Sao Paulo",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "sa-east-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "sa-east-1b"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "sa-east-1c"
        }
      },
      "Accounts": {
        "ELB": "507241528517"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-057f5d52ff7ae75ae",
          "EC2": "ami-0e2c2c29d8017dd99",
          "ECS": "ami-04f42606ac6056cc2"
        }
      }
    },
    "us-east-1": {
      "Partition": "aws",
      "Locality": "North Virginia",
      "Zones": {
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "us-east-1b"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "us-east-1c"
        },
        "d": {
          "Title": "Zone D",
          "Description": "Zone D",
          "AWSZone": "us-east-1d"
        },
        "e": {
          "Title": "Zone E",
          "Description": "Zone E",
          "AWSZone": "us-east-1e"
        }
      },
      "Accounts": {
        "ELB": "127311923021"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-00a9d4a05375b2763",
          "EC2": "ami-00eb20669e0990cb4",
          "ECS": "ami-0b84afb18c43907ba"
        }
      }
    },
    "us-east-2": {
      "Partition": "aws",
      "Locality": "Ohio",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "us-east-2a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "us-east-2b"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "us-east-2c"
        }
      },
      "Accounts": {
        "ELB": "033677994240"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-00d1f8201864cc10c",
          "EC2": "ami-0c64dd618a49aeee8",
          "ECS": "ami-020c0a39d62d1ee78"
        }
      }
    },
    "us-gov-west-1": {
      "Partition": "aws-us-gov",
      "Locality": "US",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "us-gov-west-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "us-gov-west-1b"
        }
      },
      "Accounts": {
        "ELB": "048591011584"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-66a01b07",
          "EC2": "ami-ffa61d9e"
        }
      }
    },
    "us-west-1": {
      "Partition": "aws",
      "Locality": "North California",
      "Zones": {
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "us-west-1b"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "us-west-1c"
        }
      },
      "Accounts": {
        "ELB": "027434742980"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-097ad469381034fa2",
          "EC2": "ami-0bce08e823ed38bdd",
          "ECS": "ami-02cc18e2b3ad89f49"
        }
      }
    },
    "us-west-2": {
      "Partition": "aws",
      "Locality": "Oregon",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "us-west-2a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "us-west-2b"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "us-west-2c"
        }
      },
      "Accounts": {
        "ELB": "797873946194"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-0b840e8a1ce4cdf15",
          "EC2": "ami-08d489468314a58df",
          "ECS": "ami-0563f6566c7b919d1"
        }
      }
    },
    "eu-north-1": {
      "Partition": "aws",
      "Locality": "Stockholm",
      "Zones": {
        "a": {
          "Title": "Zone A",
          "Description": "Zone A",
          "AWSZone": "eu-north-1a"
        },
        "b": {
          "Title": "Zone B",
          "Description": "Zone B",
          "AWSZone": "eu-north-1b"
        },
        "c": {
          "Title": "Zone C",
          "Description": "Zone C",
          "AWSZone": "eu-north-1c"
        }
      },
      "Accounts": {
        "ELB": "897822967062"
      },
      "AMIs": {
        "Centos": {
          "NAT": "ami-28d15f56",
          "EC2": "ami-6a1f9414",
          "ECS": "ami-04f26a2b92ed4105b"
        }
      }
    }
  },
  "Environments": {
    "alm": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        }
      }
    },
    "alpha": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 2
        }
      }
    },
    "beta": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        }
      }
    },
    "int": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        }
      }
    },
    "aat": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        }
      }
    },
    "uat": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        }
      }
    },
    "system": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        }
      }
    },
    "preprod": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        },
        "DeadLetterQueue": {
          "MaxReceives": 13
        }
      }
    },
    "stg": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        },
        "DeadLetterQueue": {
          "MaxReceives": 13
        }
      }
    },
    "prod": {
      "RDS": {
        "AutoMinorVersionUpgrade": false
      },
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        },
        "DeadLetterQueue": {
          "MaxReceives": 13
        }
      }
    },
    "trn": {
      "Operations": {
        "FlowLogs": {
          "Enabled": true,
          "Expiration": 7
        }
      }
    }
  },
  "Tiers": {
    "mgmt": {
      "Components": {
        "seg-cert": {
          "DeploymentUnits": [
            "cert"
          ]
        },
        "seg-dns": {
          "DeploymentUnits": [
            "dns"
          ],
          "Enabled": false
        },
        "seg-dashboard": {
          "DeploymentUnits": [
            "dashboard"
          ],
          "Enabled": false
        },
        "baseline": {
          "DeploymentUnits": [
            "baseline"
          ],
          "baseline": {
            "DataBuckets": {
              "opsdata": {
                "Role": "operations",
                "Lifecycles": {
                  "awslogs": {
                    "Prefix": "AWSLogs",
                    "Expiration": "_operations",
                    "Offline": "_operations"
                  },
                  "cloudfront": {
                    "Prefix": "CLOUDFRONTLogs",
                    "Expiration": "_operations",
                    "Offline": "_operations"
                  },
                  "docker": {
                    "Prefix": "DOCKERLogs",
                    "Expiration": "_operations",
                    "Offline": "_operations"
                  }
                },
                "Links": {
                  "cf_key": {
                    "Tier": "mgmt",
                    "Component": "baseline",
                    "Instance": "",
                    "Version": "",
                    "Key": "oai"
                  }
                }
              },
              "appdata": {
                "Role": "appdata",
                "Lifecycles": {
                  "global": {
                    "Expiration": "_data",
                    "Offline": "_data"
                  }
                }
              }
            },
            "Keys": {
              "ssh": {
                "Engine": "ssh"
              },
              "cmk": {
                "Engine": "cmk"
              },
              "accountcmk" : {
                "Engine" : "cmk-account"
              },
              "oai": {
                "Engine": "oai"
              }
            }
          }
        },
        "ssh": {
          "DeploymentUnits": [
            "ssh"
          ],
          "MultiAZ": true,
          "bastion": {
            "AutoScaling": {
              "DetailedMetrics": false,
              "ActivityCooldown": 180,
              "MinUpdateInstances": 0,
              "AlwaysReplaceOnUpdate": false
            }
          }
        },
        "vpc": {
          "DeploymentUnits": [
            "vpc"
          ],
          "MultiAZ": true,
          "network": {
            "RouteTables": {
              "internal": {},
              "external": {
                "Public": true
              }
            },
            "NetworkACLs": {
              "open": {
                "Rules": {
                  "in": {
                    "Priority": 200,
                    "Action": "allow",
                    "Source": {
                      "IPAddressGroups": [
                        "_global"
                      ]
                    },
                    "Destination": {
                      "IPAddressGroups": [
                        "_localnet"
                      ],
                      "Port": "any"
                    },
                    "ReturnTraffic": false
                  },
                  "out": {
                    "Priority": 200,
                    "Action": "allow",
                    "Source": {
                      "IPAddressGroups": [
                        "_localnet"
                      ]
                    },
                    "Destination": {
                      "IPAddressGroups": [
                        "_global"
                      ],
                      "Port": "any"
                    },
                    "ReturnTraffic": false
                  }
                }
              }
            }
          }
        },
        "igw": {
          "DeploymentUnits": [
            "igw"
          ],
          "gateway": {
            "Engine": "igw",
            "Destinations": {
              "default": {
                "IPAddressGroups": "_global",
                "Links": {
                  "external": {
                    "Tier": "mgmt",
                    "Component": "vpc",
                    "Version": "",
                    "Instance": "",
                    "RouteTable": "external"
                  }
                }
              }
            }
          }
        },
        "nat": {
          "DeploymentUnits": [
            "nat"
          ],
          "gateway": {
            "Engine": "natgw",
            "Destinations": {
              "default": {
                "IPAddressGroups": "_global",
                "Links": {
                  "internal": {
                    "Tier": "mgmt",
                    "Component": "vpc",
                    "Version": "",
                    "Instance": "",
                    "RouteTable": "internal"
                  }
                }
              }
            }
          }
        },
        "vpcendpoint": {
          "DeploymentUnits": [
            "vpcendpoint"
          ],
          "gateway": {
            "Engine": "vpcendpoint",
            "Destinations": {
              "default": {
                "NetworkEndpointGroups": [
                  "storage",
                  "logs"
                ],
                "Links": {
                  "internal": {
                    "Tier": "mgmt",
                    "Component": "vpc",
                    "Version": "",
                    "Instance": "",
                    "RouteTable": "internal"
                  },
                  "external": {
                    "Tier": "mgmt",
                    "Component": "vpc",
                    "Version": "",
                    "Instance": "",
                    "RouteTable": "external"
                  }
                }
              }
            }
          }
        }
      }
    },
    "gbl": {
      "Components": {
        "cfredirect": {
          "Lambda": {
            "Instances": {
              "default": {
                "Versions": {
                  "v1": {
                    "DeploymentUnits": [
                      "cfredirect-v1"
                    ],
                    "Enabled": false,
                    "Fragment": "_cfredirect-v1"
                  }
                }
              }
            },
            "DeploymentType": "EDGE",
            "RunTime": "nodejs8.10",
            "MemorySize": 128,
            "Timeout": 1,
            "FixedCodeVersion": {},
            "Functions": {
              "cfredirect": {
                "Handler": "index.handler",
                "VPCAccess": false,
                "Permissions": {
                  "Decrypt": false,
                  "AsFile": false,
                  "AppData": false,
                  "AppPublic": false
                },
                "PredefineLogGroup": false
              }
            }
          }
        }
      }
    }
  },
  "Storage": {
    "default": {
      "EC2": {
        "Volumes": {
          "codeontap": {
            "Device": "/dev/sdp",
            "Size": "30"
          }
        },
        "ECS": {},
        "ElasticSearch": {},
        "ComputeCluster": {},
        "bastion": {}
      }
    }
  },
  "Processors": {
    "default": {
      "NAT": {
        "Processor": "t2.micro"
      },
      "bastion": {
        "Processor": "t2.micro"
      },
      "EC2": {
        "Processor": "t2.micro"
      },
      "EMR": {
        "Processor": "m4.large",
        "DesiredCorePerZone": 1,
        "DesiredTaskPerZone": 1
      },
      "ComputeCluster": {
        "Processor": "t2.micro",
        "MinPerZone": 1,
        "MaxPerZone": 1,
        "DesiredPerZone": 1
      },
      "ECS": {
        "Processor": "t2.medium",
        "MinPerZone": 1,
        "MaxPerZone": 1,
        "DesiredPerZone": 1
      },
      "ElastiCache": {
        "Processor": "cache.t2.micro",
        "CountPerZone": 1
      },
      "db": {
        "Processor": "db.t2.small",
        "MinPerZone": 1,
        "MaxPerZone": 1,
        "DesiredPerZone": 1
      },
      "ElasticSearch": {
        "Processor": "t2.medium.elasticsearch",
        "CountPerZone": 1,
        "Master" : {
          "Processor" : "t2.small.elasticsearch",
          "CountPerZone" : 0
        }
      },
      "service": {
        "DesiredPerZone": 1,
        "MinPerZone": 1,
        "MaxPerZone": 1
      }
    }
  },
  "Product": {
    "cfredirect-v1": {
      "Region": "us-east-1"
    },
    "Builds": {
      "Data": {
        "Environment": "int"
      },
      "Code": {
        "Environment": "int"
      }
    }
  },
  "Segment": {
    "Network": {
      "InternetAccess": true,
      "Tiers": {
        "Order": [
          "web",
          "msg",
          "app",
          "db",
          "dir",
          "ana",
          "api",
          "spare",
          "elb",
          "ilb",
          "spare",
          "spare",
          "spare",
          "spare",
          "spare",
          "mgmt"
        ]
      },
      "Zones": {
        "Order": [
          "a",
          "b",
          "spare",
          "spare"
        ]
      }
    },
    "NAT": {
      "Enabled": true,
      "MultiAZ": false,
      "Hosted": true
    },
    "Bastion": {
      "Enabled": true,
      "Active": false,
      "IPAddressGroups": []
    },
    "ConsoleOnly": false,
    "S3": {
      "IncludeTenant": false
    },
    "RotateKey": true,
    "Tiers": {
      "Order": [
        "elb",
        "api",
        "web",
        "msg",
        "dir",
        "ilb",
        "app",
        "db",
        "ana",
        "mgmt",
        "docs",
        "gbl",
        "external"
      ]
    }
  },
  "CertificateBehaviours": {
    "External": false,
    "Wildcard": true,
    "IncludeInHost": {
      "Product": false,
      "Segment": false,
      "Tier": false
    },
    "HostParts": [
      "Host",
      "Tier",
      "Component",
      "Instance",
      "Version",
      "Segment",
      "Environment",
      "Product"
    ],
    "Qualifiers": {
      "prod": {
        "IncludeInHost": {
          "Environment": false
        },
        "IncludeInDomain": {
          "Environment": false
        }
      }
    }
  },
  "LogFiles": {
    "/var/log/cfn-init.log": {
      "FilePath": "/var/log/cfn-init.log",
      "TimeFormat": "%b %d %H:%M:%S"
    },
    "/var/log/cfn-init-cmd.log": {
      "FilePath": "/var/log/cfn-init-cmd.log",
      "TimeFormat": "%b %d %H:%M:%S"
    },
    "/var/log/cloud-init.log": {
      "FilePath": "/var/log/cloud-init.log",
      "TimeFormat": "%b %d %H:%M:%S"
    },
    "/var/log/cloud-init-output.log": {
      "FilePath": "/var/log/cloud-init-output.log",
      "TimeFormat": "%b %d %H:%M:%S"
    },
    "/var/log/amazon/ssm/amazon-ssm-agent.log": {
      "FilePath": "/var/log/amazon/ssm/amazon-ssm-agent.log",
      "MultiLinePattern": "^INFO"
    },
    "/var/log/ecs/ecs-init.log": {
      "FilePath": "/var/log/ecs/ecs-init.log",
      "TimeFormat": "%b %d %H:%M:%S"
    },
    "/var/log/ecs/ecs-agent.log": {
      "FilePath": "/var/log/ecs/ecs-agent.log",
      "TimeFormat": "%b %d %H:%M:%S"
    },
    "/var/log/ecs/audit.log": {
      "FilePath": "/var/log/ecs/audit.log",
      "TimeFormat": "%b %d %H:%M:%S"
    }
  },
  "LogFileGroups": {
    "aws-ecs": {
      "LogFiles": [
        "/var/log/ecs/ecs-init.log",
        "/var/log/ecs/ecs-agent.log",
        "/var/log/ecs/audit.log"
      ]
    },
    "aws-system": {
      "LogFiles": [
        "/var/log/cfn-init.log",
        "/var/log/cfn-init-cmd.log",
        "/var/log/cloud-init.log",
        "/var/log/cloud-init-output.log",
        "/var/log/amazon/ssm/amazon-ssm-agent.log"
      ]
    }
  },
  "LogFileProfiles": {
    "default": {
      "EC2": {
        "LogFileGroups": [
          "system",
          "aws-system",
          "security",
          "docker"
        ]
      },
      "ComputeCluster": {
        "LogFileGroups": [
          "system",
          "aws-system",
          "security",
          "docker"
        ]
      },
      "ECS": {
        "LogFileGroups": [
          "system",
          "aws-system",
          "security",
          "docker",
          "aws-ecs"
        ]
      },
      "bastion": {
        "LogFileGroups": [
          "system",
          "aws-system",
          "security"
        ]
      }
    }
  },
  "CORSProfiles": {
    "S3Write": {
      "AllowedHeaders": [
        "Content-Length",
        "Content-Type",
        "Content-MD5",
        "Authorization",
        "Expect",
        "x-amz-content-sha256",
        "x-amz-security-token"
      ]
    },
    "S3Delete": {
      "AllowedHeaders": [
        "Content-Length",
        "Content-Type",
        "Content-MD5",
        "Authorization",
        "Expect",
        "x-amz-content-sha256",
        "x-amz-security-token"
      ]
    }
  },
  "BootstrapProfiles": {
    "default": {
      "EC2": {
        "BootStraps": []
      },
      "ECS": {
        "BootStraps": []
      },
      "ComputeCluster": {
        "BootStraps": []
      },
      "bastion": {
        "BootStraps": []
      }
    }
  },
  "WAFValueSets": {
    "default": {
      "badcookies": [
        "bad-cookie"
      ],
      "badtokens": [
        "bad-tokens"
      ],
      "loginpaths": [
        "/login"
      ],
      "traversalpaths": [
        "../",
        "://"
      ],
      "adminpaths": [
        "/admin"
      ],
      "adminips": [
        "0.0.0.0/0"
      ],
      "phpquery": [
        "_SERVER[",
        "_ENV[",
        "auto_prepend_file=",
        "auto_append_file=",
        "allow_url_include=",
        "disable_functions=",
        "open_basedir=",
        "safe_mode="
      ],
      "phpuri": [
        "php",
        "/"
      ],
      "maxuri": 1024,
      "maxquery": 1024,
      "maxbody": 4096,
      "maxcookie": 4093,
      "csrfsize": 36,
      "uristartswith": [
        "/includes"
      ],
      "uriendswith": [
        ".cfg",
        ".conf",
        ".config",
        ".ini",
        ".log",
        ".bak",
        ".backup"
      ],
      "blacklistedips": [],
      "whitelistedips": [],
      "sqlheaders": [
        {
          "Type": "HEADER",
          "Data": "cookie"
        },
        {
          "Type": "HEADER",
          "Data": "authorization"
        }
      ],
      "badcookieheaders": [
        {
          "Type": "HEADER",
          "Data": "cookie"
        }
      ],
      "badtokenheaders": [
        {
          "Type": "HEADER",
          "Data": "authorization"
        }
      ],
      "xssheaders": [
        {
          "Type": "HEADER",
          "Data": "cookie"
        }
      ],
      "csrfheaders": [
        "x-csrf-token"
      ]
    }
  },
  "WAFConditions": {
    "OWASP2017A1": {
      "Type": "SqlInjectionMatch",
      "Filters": [
        {
          "FieldsToMatch": [
            {
              "Type": "URI"
            },
            {
              "Type": "QUERY_STRING"
            },
            {
              "Type": "BODY"
            },
            "sqlheaders"
          ],
          "Transformations": [
            "URL_DECODE",
            "HTML_ENTITY_DECODE"
          ]
        }
      ]
    },
    "OWASP2017A2-1": {
      "Type": "ByteMatch",
      "Description": "Bad cookies",
      "Filters": [
        {
          "FieldsToMatch": {
            "Type": "HEADER",
            "Data": "cookie"
          },
          "Constraints": "CONTAINS",
          "Targets": [
            "badcookies"
          ],
          "Transformations": [
            "URL_DECODE",
            "HTML_ENTITY_DECODE"
          ]
        }
      ]
    },
    "OWASP2017A2-2": {
      "Type": "ByteMatch",
      "Description": "Bad tokens",
      "Filters": [
        {
          "FieldsToMatch": {
            "Type": "HEADER",
            "Data": "authorisation"
          },
          "Constraints": "ENDS_WITH",
          "Targets": [
            "badtokens"
          ],
          "Transformations": [
            "URL_DECODE",
            "HTML_ENTITY_DECODE"
          ]
        }
      ]
    },
    "OWASP2017A2-3": {
      "Type": "ByteMatch",
      "Description": "Login rate limiting",
      "Filters": [
        {
          "FieldsToMatch": {
            "Type": "URI"
          },
          "Constraints": "STARTS_WITH",
          "Targets": [
            "loginpaths"
          ],
          "Transformations": [
            "URL_DECODE",
            "HTML_ENTITY_DECODE"
          ]
        }
      ]
    },
    "OWASP2017A3": {
      "Type": "XssMatch",
      "Filters": [
        {
          "FieldsToMatch": [
            {
              "Type": "URI"
            },
            {
              "Type": "QUERY_STRING"
            },
            {
              "Type": "BODY"
            },
            "xssheaders"
          ],
          "Transformations": [
            "URL_DECODE",
            "HTML_ENTITY_DECODE"
          ]
        }
      ]
    },
    "OWASP2017A4-1": {
      "Type": "ByteMatch",
      "Description": "Path traversal",
      "Filters": [
        {
          "FieldsToMatch": [
            {
              "Type": "URI"
            },
            {
              "Type": "QUERY_STRING"
            }
          ],
          "Constraints": "CONTAINS",
          "Targets": [
            "traversalpaths"
          ],
          "Transformations": [
            "URL_DECODE",
            "HTML_ENTITY_DECODE"
          ]
        }
      ]
    },
    "OWASP2017A4-2": {
      "Type": "ByteMatch",
      "Description": "Admin Functions",
      "Filters": [
        {
          "FieldsToMatch": {
            "Type": "URI"
          },
          "Constraints": "STARTS_WITH",
          "Targets": [
            "adminpaths"
          ],
          "Transformations": "URL_DECODE"
        }
      ]
    },
    "OWASP2017A4-3": {
      "Type": "IPMatch",
      "Description": "Admin Functions",
      "Filters": [
        {
          "Targets": [
            "adminips"
          ]
        }
      ]
    },
    "OWASP2017A5-PHP": {
      "Type": "ByteMatch",
      "Description": "Insecure PHP Configuration",
      "Filters": [
        {
          "FieldsToMatch": {
            "Type": "QUERY_STRING"
          },
          "Constraints": "CONTAINS",
          "Targets": [
            "phpquery"
          ],
          "Transformations": "URL_DECODE"
        },
        {
          "FieldsToMatch": {
            "Type": "URI"
          },
          "Constraints": "ENDS_WITH",
          "Targets": [
            "phpuri"
          ],
          "Transformations": "URL_DECODE"
        }
      ]
    },
    "OWASP2017A7": {
      "Type": "SizeConstraint",
      "Description": "Basic size limits",
      "Filters": [
        {
          "FieldsToMatch": {
            "Type": "URI"
          },
          "Sizes": [
            "maxuri"
          ],
          "Operators": [
            "GT"
          ],
          "Transformations": "NONE"
        },
        {
          "FieldsToMatch": {
            "Type": "QUERY_STRING"
          },
          "Sizes": [
            "maxquery"
          ],
          "Operators": [
            "GT"
          ],
          "Transformations": "NONE"
        },
        {
          "FieldsToMatch": {
            "Type": "BODY"
          },
          "Sizes": [
            "maxbody"
          ],
          "Operators": [
            "GT"
          ],
          "Transformations": "NONE"
        },
        {
          "FieldsToMatch": {
            "Type": "HEADER",
            "Data": "cookie"
          },
          "Sizes": [
            "maxcookie"
          ],
          "Operators": [
            "GT"
          ],
          "Transformations": "NONE"
        }
      ]
    },
    "OWASP2017A8-1": {
      "Type": "ByteMatch",
      "Description": "CSRF Method",
      "Filters": [
        {
          "FieldsToMatch": {
            "Type": "METHOD"
          },
          "Constraints": "EXACTLY",
          "Targets": [
            "post"
          ],
          "Transformations": "LOWERCASE"
        }
      ]
    },
    "OWASP2017A8-2": {
      "Type": "SizeConstraint",
      "Description": "CSRF Size",
      "Filters": [
        {
          "FieldsToMatch": [
            "csrfheaders"
          ],
          "Sizes": [
            "csrfsize"
          ],
          "Operators": [
            "EQ"
          ],
          "Transformations": "NONE"
        }
      ]
    },
    "OWASP2017A9": {
      "Type": "ByteMatch",
      "Description": "Known vulnerabilities",
      "Filters": [
        {
          "FieldsToMatch": {
            "Type": "URI"
          },
          "Constraints": "STARTS_WITH",
          "Targets": [
            "uristartswith"
          ],
          "Transformations": "LOWERCASE"
        },
        {
          "FieldsToMatch": {
            "Type": "URI"
          },
          "Constraints": "ENDS_WITH",
          "Targets": [
            "uriendswith"
          ],
          "Transformations": "LOWERCASE"
        }
      ]
    },
    "blacklist": {
      "Type": "IPMatch",
      "Description": "Blacklist",
      "Filters": [
        {
          "Targets": [
            "blacklistedips"
          ]
        }
      ]
    },
    "whitelist": {
      "Type": "IPMatch",
      "Description": "Whitelist",
      "Filters": [
        {
          "Targets": [
            "whitelistedips"
          ]
        }
      ]
    }
  },
  "WAFRules": {
    "OWASP2017A1": {
      "Description": "SQL Injection protections",
      "NameSuffix": "owasp-sql",
      "Conditions": [
        {
          "Condition": "OWASP2017A1",
          "Negated": false
        }
      ]
    },
    "OWASP2017A2": {
      "Description": "Broken Tokens",
      "NameSuffix": "owasp-tokens",
      "Conditions": [
        {
          "Condition": "OWASP2017A2-1",
          "Negated": false
        },
        {
          "Condition": "OWASP2017A2-2",
          "Negated": false
        }
      ]
    },
    "OWASP2017A3": {
      "Description": "Cross Site Scripting protections",
      "NameSuffix": "owasp-xss",
      "Conditions": [
        {
          "Condition": "OWASP2017A3",
          "Negated": false
        }
      ]
    },
    "OWASP2017A4-1": {
      "Description": "Path Traversal",
      "NameSuffix": "owasp-paths",
      "Conditions": [
        {
          "Condition": "OWASP2017A4-1",
          "Negated": false
        }
      ]
    },
    "OWASP2017A4-2": {
      "Description": "Admin path protections",
      "NameSuffix": "owasp-admin-paths",
      "Conditions": [
        {
          "Condition": "OWASP2017A4-2",
          "Negated": false
        },
        {
          "Condition": "OWASP2017A4-3",
          "Negated": true
        }
      ]
    },
    "OWASP2017A5-PHP": {
      "Description": "PHP Specific protections",
      "NameSuffix": "owasp-php",
      "Conditions": [
        {
          "Condition": "OWASP2017A5-PHP",
          "Negated": false
        }
      ]
    },
    "OWASP2017A7": {
      "Description": "Size Constraints",
      "NameSuffix": "owasp-size",
      "Conditions": [
        {
          "Condition": "OWASP2017A7",
          "Negated": false
        }
      ]
    },
    "OWASP2017A8": {
      "Description": "CSRF Detection",
      "NameSuffix": "owasp-csrf",
      "Conditions": [
        {
          "Condition": "OWASP2017A8-1",
          "Negated": false
        },
        {
          "Condition": "OWASP2017A8-2",
          "Negated": true
        }
      ]
    },
    "OWASP2017A9": {
      "Description": "Known Vulnerabilities",
      "NameSuffix": "owasp-vulnerabilities",
      "Conditions": [
        {
          "Condition": "OWASP2017A9",
          "Negated": false
        }
      ]
    },
    "blacklist": {
      "Description": "Blacklist",
      "NameSuffix": "blacklist",
      "Conditions": [
        {
          "Condition": "blacklist",
          "Negated": false
        }
      ]
    },
    "whitelist": {
      "Description": "Whitelist",
      "NameSuffix": "whitelist",
      "Conditions": [
        {
          "Condition": "whitelist",
          "Negated": false
        }
      ]
    }
  },
  "WAFRuleGroups": {
    "OWASP2017-Basic": {
      "WAFRules": [
        "OWASP2017A1",
        "OWASP2017A3",
        "OWASP2017A7",
        "OWASP2017A9"
      ]
    }
  },
  "WAFProfiles": {
    "OWASP2017": {
      "Rules": [
        {
          "RuleGroup": "OWASP2017-Basic",
          "Action": "BLOCK"
        }
      ],
      "DefaultAction": "ALLOW"
    },
    "whitelist": {
      "Rules": [
        {
          "Rule": "whitelist",
          "Action": "ALLOW"
        }
      ],
      "DefaultAction": "BLOCK"
    }
  },
  "SecurityProfiles": {
    "default": {
      "lb": {
        "application": {
          "HTTPSProfile": "ELBSecurityPolicy-TLS-1-2-2017-01",
          "WAFProfile": "OWASP2017",
          "WAFValueSet": "default"
        },
        "classic": {
          "HTTPSProfile": "ELBSecurityPolicy-2016-08"
        }
      },
      "apigateway": {
        "HTTPSProfile": "TLSv1",
        "ProtocolPolicy": "redirect-to-https",
        "WAFProfile": "OWASP2017",
        "WAFValueSet": "default"
      },
      "spa": {
        "HTTPSProfile": "TLSv1",
        "WAFProfile": "OWASP2017",
        "WAFValueSet": "default"
      },
      "cdn": {
        "HTTPSProfile": "TLSv1",
        "WAFProfile": "OWASP2017",
        "WAFValueSet": "default"
      },
      "db": {
        "SSLCertificateAuthority": "rds-ca-2019"
      },
      "es" : {
        "ProtocolPolicy" : "https-only"
      }
    }
  },
  "LogFilters": {
    "_sns-success": {
      "Pattern": "{ $.status = \"SUCCESS\" }"
    },
    "_sns-failure": {
      "Pattern": "{ $.status = \"FAILURE\" }"
    }
  },
  "DeploymentProfiles": {
    "_frontdoor": {
      "Modes": {
        "maintenance": {
          "lb": {
            "PortMappings": {
              "httpsmaintenance": {
                "Mapping": "https",
                "Priority": 50,
                "Fixed": {
                  "Message": "This application is currently undergoing scheduled maintenance. Please try again later.",
                  "ContentType": "text/plain",
                  "StatusCode": "503"
                }
              }
            }
          }
        }
      }
    },
    "_hibernate": {
      "Modes": {
        "maintenance": {
          "ecs": {
            "Hibernate": {
              "Enabled": true
            }
          },
          "rds": {
            "Hibernate": {
              "Enabled": true
            }
          },
          "cache": {
            "Hibernate": {
              "Enabled": true
            }
          }
        }
      }
    },
    "_moncpumem": {
      "Modes": {
        "*": {
          "ecs": {
            "Alerts": {
              "HighHostMemoryUsage": {
                "Description": "High Memory usage on ECS Host cluster",
                "Name": "HighHostMemoryUsage",
                "Metric": "MemoryUtilization",
                "Threshold": 95,
                "Severity": "Error",
                "Statistic": "Average",
                "Periods": 2,
                "Resource": {
                  "Type": "ecs"
                }
              },
              "HighHostCPUUsage": {
                "Description": "High CPU usage on ECS Host cluster",
                "Name": "HighHostCPUUsage",
                "Metric": "CPUUtilization",
                "Threshold": 95,
                "Severity": "Error",
                "Statistic": "Average",
                "Periods": 2,
                "Resource": {
                  "Type": "ecs"
                }
              }
            }
          },
          "service": {
            "Alerts": {
              "HighCPUUsage": {
                "Description": "Higher than expected CPU usage detected",
                "Name": "HighCPUUsage",
                "Metric": "CPUUtilization",
                "Threshold": 150,
                "Severity": "Warning",
                "Statistic": "Average"
              },
              "HighMemoryUsage": {
                "Description": "Higher than expected memory usage detected",
                "Name": "HighMemoryUsage",
                "Metric": "MemoryUtilization",
                "Threshold": 120,
                "Severity": "Warning",
                "Statistic": "Average"
              }
            }
          },
          "rds": {
            "Alerts": {
              "HighCPUUsage": {
                "Description": "Database under high CPU load",
                "Name": "HighCPUUsage",
                "Metric": "CPUUtilization",
                "Threshold": 90,
                "Severity": "Error",
                "Statistic": "Average",
                "Periods": 2
              },
              "LowDiskSpace": {
                "Description": "Database disk space is getting low only 1Gb free",
                "Name": "LowDiskSpace",
                "Metric": "FreeStorageSpace",
                "Threshold": 1024000000,
                "Severity": "Error",
                "Statistic": "Maximum",
                "Periods": 1,
                "Operator": "LessThanOrEqualToThreshold"
              }
            }
          },
          "cache": {
            "Alerts": {
              "HighCPUUsage": {
                "Description": "Redis cache under high CPU load",
                "Name": "HighCPUUsage",
                "Metric": "EngineCPUUtilization",
                "Threshold": 90,
                "Severity": "Error",
                "Statistic": "Average",
                "Periods": 2
              }
            }
          }
        }
      }
    }
  },
  "PlacementProfiles": {
    "default": {
      "default": {
        "Provider": "aws",
        "Region": "ap-southeast-2",
        "DeploymentFramework": "cf"
      }
    }
  },
  "NetworkEndpointGroups": {
    "compute": {
      "Services": [
        "ec2",
        "ec2messages",
        "logs",
        "elasticloadbalancing",
        "monitoring"
      ]
    },
    "security": {
      "Services": [
        "kms",
        "logs"
      ]
    },
    "configurationMgmt": {
      "Services": [
        "ssm",
        "ssmmessages"
      ]
    },
    "ecs": {
      "Services": [
        "ecs",
        "ecs-agent",
        "ecs-telemetry",
        "ecr.api",
        "ecr.dkr"
      ]
    },
    "serverless": {
      "Services": [
        "sns",
        "sqs",
        "execute-api"
      ]
    },
    "logs": {
      "Services": [
        "logs"
      ]
    },
    "storage": {
      "Services": [
        "s3",
        "dynamodb"
      ]
    }
  },
  "BaselineProfiles": {
    "default": {
      "OpsData": "opsdata",
      "AppData": "appdata",
      "Encryption": "cmk",
      "SSHKey": "ssh",
      "CDNOriginKey": "oai"
    }
  }
}
  /]
[/#macro]
