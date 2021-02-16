[#ftl]

[#-- Intial seeding of settings data based on input data --]
[#macro shared_input_shared_masterdata_seed ]
  [@addMasterData
    data=
      {
        "Environments": {
          "alm": {
            "Title": "Application Lifecycle Management Environment",
            "Description": "Normally only one environment for the alm. Entry mainly here for naming consistency",
            "Category": "alm",
            "Operations": {
              "Expiration": 90
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "shared": {
            "Title": "Shared Services Environment",
            "Description": "One shared environment per account. Entry mainly here for naming consistency",
            "Category": "alm",
            "Operations": {
              "Expiration": 30
            }
          },
          "dev": {
            "Title": "Development Environment",
            "Description": "Potentially holds individual dev servers for multiple devs",
            "Category": "dev",
            "Operations": {
              "Expiration": 14
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "alpha": {
            "Title": "Alpha Environment",
            "Description": "Prototyping environment according to DTO classification",
            "Category": "test",
            "Operations": {
              "Expiration": 14
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "beta": {
            "Title": "Beta Environment",
            "Description": "Preproduction environment according to DTO classification",
            "Category": "stg",
            "MultiAZ": true,
            "Operations": {
              "Expiration": 90
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "int": {
            "Name": "integration",
            "Title": "Integration Environment",
            "Description": "Mainly for devs to confirm components work together",
            "Category": "test",
            "Operations": {
              "Expiration": 30
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "aat": {
            "Name": "automatedacceptance",
            "Title": "Automated Acceptance Environment",
            "Description": "Execution of automated tests",
            "Category": "test",
            "Operations": {
              "Expiration": 30
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "uat": {
            "Name": "useracceptance",
            "Title": "User Acceptance Environment",
            "Description": "Manual customer testing",
            "Category": "test",
            "Operations": {
              "Expiration": 30
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "system": {
            "Name" : "system",
            "Title": "System Test Environment",
            "Description": "Same as UAT",
            "Category": "test",
            "MultiAZ": true,
            "Operations": {
              "Expiration": 30
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "preprod": {
            "Name": "preproduction",
            "Title": "Preproduction Environment",
            "Description": "Deployment, performance, volume testing",
            "Category": "stg",
            "MultiAZ": true,
            "Operations": {
              "Expiration": 90
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "stg": {
            "Name": "staging",
            "Title": "Staging Environment",
            "Description": "Deployment, performance, volume testing. Staging is used both as a specific environment and as a category of environments.",
            "Category": "stg",
            "MultiAZ": true,
            "Operations": {
              "Expiration": 90
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
            }
          },
          "prod": {
            "Name": "production",
            "Title": "Production Environment",
            "Description": "Kind of obvious...",
            "Category": "prod",
            "MultiAZ": true,
            "Operations": {
              "Expiration": 365
            },
            "DomainBehaviours": {
              "Segment": "naked"
            },
            "OSPatching" : {
              "SecurityOnly" : true
            }
          },
          "trn": {
            "Name": "training",
            "Title": "Training Environment",
            "Description": "",
            "Category": "prod",
            "Operations": {
              "Expiration": 90
            },
            "DomainBehaviours": {
              "Segment": "segmentInHost"
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
          "RotateKeys": true,
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
              "gbl"
            ]
          }
        },
        "Categories": {
          "alm": {
            "Title": "Application Lifecycle Management Environments"
          },
          "account": {
            "Title": "Account Resources"
          },
          "dev": {
            "Name": "development",
            "Title": "Development Environments"
          },
          "test": {
            "Name": "testing",
            "Title": "Testing Environments"
          },
          "stg": {
            "Name": "staging",
            "Title": "Staging Environments"
          },
          "prod": {
            "Name": "production",
            "Title": "Production Environments"
          }
        },
        "Tiers": {
          "web": {
            "Name" : "web",
            "Title": "Web Tier",
            "Description": "Supports HMI",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable" : "internal",
              "NetworkACL" : "open"
            }
          },
          "api": {
            "Name" : "api",
            "Title": "API Tier",
            "Description": "Supports externally exposed APIs",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable" : "internal",
              "NetworkACL" : "open"
            }
          },
          "msg": {
            "Name": "messaging",
            "Title": "Messaging Tier",

            "Description": "Supports system-to-system based interactions/services",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable" : "internal",
              "NetworkACL" : "open"
            }
          },
          "app": {
            "Name": "application",
            "Title": "Applications Tier",
            "Description": "Supports application logic execution",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable" : "internal",
              "NetworkACL" : "open"
            }
          },
          "db": {
            "Name": "database",
            "Title": "Database Tier",
            "Description": "Supports long term storage of content and customer data",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable" : "internal",
              "NetworkACL" : "open"
            }
          },
          "dir": {
            "Name": "directories",
            "Title": "Directories Tier",
            "Description": "Supports directories or domain controllers",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable" : "internal",
              "NetworkACL" : "open"
            }
          },
          "ana": {
            "Name": "analytics",
            "Title": "Analytics Tier",
            "Description": "Suports things like search engines",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable" : "internal",
              "NetworkACL" : "open"
            }
          },
          "elb": {
            "Name" : "elb",
            "Title": "External Load Balancer Tier",
            "Description": "Publically accessible application load balancers",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable": "external",
              "NetworkACL" : "open"
            }
          },
          "ilb": {
            "Name" : "ilb",
            "Title": "Internal Load Balancer Tier",
            "Description": "Internally accessible application load balancers",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable" : "internal",
              "NetworkACL" : "open"
            }
          },
          "mgmt": {
            "Name": "management",
            "Title": "Management Tier",
            "Description": "Supports ssh based host access and internet access for internal hosts",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Instance" : "",
                "Version" : ""
              },
              "RouteTable": "external",
              "NetworkACL" : "open"
            }
          },
          "shared": {
            "Name" : "shared",
            "Title": "Shared Tier",
            "Description": "Shared Tier",
            "Network": {
              "Enabled": true,
              "Link" : {
                "Tier" : "mgmt",
                "Component" : "vpc",
                "Version" : "",
                "Instance" : ""
              },
              "RouteTable": "external",
              "NetworkACL" : "open"
            }
          },
          "docs": {
            "Name": "documentation",
            "Title": "Docs Tier",
            "Description": "Non-network Tier For documentation generation",
            "Network" : {
              "Enabled" : false
            }
          },
          "gbl": {
            "Name": "global",
            "Title": "Global Tier",
            "Description": "Components which are used for Global Services",
            "Network": {
              "Enabled": false
            }
          }
        },
        "Ports": {
          "couchdb": {
            "Port": 5984,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "ednp": {
            "Port": 25672,
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "elasticsearch": {
            "Port": 9200,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "epmd": {
            "Port": 4369,
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "http": {
            "Port": 80,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "httpalt": {
            "Port": 8080,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "httpredirect": {
            "Port": 80,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "2",
              "UnhealthyThreshold": "3",
              "Interval": "30",
              "Timeout": "5",
              "SuccessCodes": "301"
            }
          },
          "https": {
            "Port": 443,
            "Protocol": "HTTPS",
            "IPProtocol": "tcp",
            "Certificate": true,
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "kibana": {
            "Port": 5601,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "memcached": {
            "Port": 11211,
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "meteor": {
            "Port": 3000,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "mongodb": {
            "Port": 27017,
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "mysql": {
            "Port": 3306,
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "node": {
            "Port": 9000,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "play": {
            "Port": 9000,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "playws": {
            "Port": 9000,
            "Protocol": "TCP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "postgresql": {
            "Port": 5432,
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "rabbit": {
            "Port": 5672,
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "rabbit-ui": {
            "Port": 15672,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "2",
              "UnhealthyThreshold": "3",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "rabbitmq": {
            "Port": 5671,
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "rabbitmq-ui": {
            "Port": 15671,
            "Protocol": "HTTP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "2",
              "UnhealthyThreshold": "3",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "redis": {
            "Port": 6379,
            "Protocol": "TCP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "smtp": {
            "Port": 25,
            "Protocol": "TCP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "nfs": {
            "Port": 2049,
            "Protocol": "TCP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "hsmtp": {
            "Port": 2025,
            "Protocol": "TCP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "ssh": {
            "Port": 22,
            "Protocol": "TCP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "ws": {
            "Port": 80,
            "Protocol": "TCP",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "wss": {
            "Port": 443,
            "Protocol": "SSL",
            "IPProtocol": "tcp",
            "HealthCheck": {
              "Path": "/",
              "HealthyThreshold": "3",
              "UnhealthyThreshold": "5",
              "Interval": "30",
              "Timeout": "5"
            }
          },
          "ephemeraltcp" : {
            "PortRange" : {
              "From" : 1024,
              "To" : 65535
            },
            "IPProtocol" : "tcp"
          },
          "ephemeraludp" : {
            "PortRange" : {
              "From" : 1024,
              "To" : 65535
            },
            "IPProtocol" : "udp"
          },
          "any" : {
            "PortRange" : {
              "From" : 0,
              "To" : 65535
            },
            "IPProtocol" : "all"
          },
          "anyudp" : {
            "PortRange" : {
              "From" : 0,
              "To" : 65535
            },
            "IPProtocol" : "udp"
          },
          "anytcp" : {
            "PortRange" : {
              "From" : 0,
              "To" : 65535
            },
            "IPProtocol" : "tcp"
          },
          "anyicmp" : {
            "IPProtocol" : "icmp",
            "ICMP" : {
              "Code" : -1,
              "Type" : -1
            }
          }
        },
        "PortMappings": {
          "couchdb": {
            "Source": "https",
            "Destination": "couchdb"
          },
          "elasticsearch": {
            "Source": "https",
            "Destination": "elasticsearch"
          },
          "http": {
            "Source": "http",
            "Destination": "http"
          },
          "httpalt": {
            "Source": "http",
            "Destination": "httpalt"
          },
          "httpredirect": {
            "Source": "http",
            "Destination": "httpredirect"
          },
          "https": {
            "Source": "https",
            "Destination": "http"
          },
          "httpsalt": {
            "Source": "https",
            "Destination": "httpalt"
          },
          "kibana": {
            "Source": "https",
            "Destination": "kibana"
          },
          "meteor": {
            "Source": "https",
            "Destination": "meteor"
          },
          "node": {
            "Source": "https",
            "Destination": "node"
          },
          "play": {
            "Source": "https",
            "Destination": "play"
          },
          "playwss": {
            "Source": "wss",
            "Destination": "playws"
          },
          "smtp": {
            "Source": "smtp",
            "Destination": "smtp"
          },
          "hsmtp": {
            "Source": "smtp",
            "Destination": "hsmtp"
          },
          "ws": {
            "Source": "ws",
            "Destination": "ws"
          },
          "wss": {
            "Source": "wss",
            "Destination": "ws"
          }
        },
        "LogFiles": {
          "/var/log/dmesg": {
            "FilePath": "/var/log/dmesg"
          },
          "/var/log/messages": {
            "FilePath": "/var/log/messages",
            "TimeFormat": "%b %d %H:%M:%S"
          },
          "/var/log/secure": {
            "FilePath": "/var/log/secure",
            "TimeFormat": "%b %d %H:%M:%S"
          },
          "/var/log/cron": {
            "FilePath": "/var/log/cron",
            "TimeFormat": "%b %d %H:%M:%S"
          },
          "/var/log/audit/audit.log": {
            "FilePath": "/var/log/audit/audit.log",
            "MultiLinePattern": "^type"
          },
          "/var/log/aide/aide.log": {
            "FilePath": "/var/log/aide/aide.log",
            "TimeFormat": "%b %d %H:%M:%S"
          },
          "/var/log/docker": {
            "FilePath": "/var/log/docker",
            "TimeFormat": "%b %d %H:%M:%S"
          }
        },
        "LogFileGroups": {
          "security": {
            "LogFiles": [
              "/var/log/secure",
              "/var/log/audit/audit.log",
              "/var/log/aide/aide.log"
            ]
          },
          "system": {
            "LogFiles": [
              "/var/log/dmesg",
              "/var/log/messages",
              "/var/log/cron"
            ]
          },
          "docker": {
            "LogFiles": [
              "/var/log/docker"
            ]
          }
        },
        "CORSProfiles": {
          "S3Read": {
            "AllowedOrigins": [
              "*"
            ],
            "AllowedMethods": [
              "GET",
              "HEAD"
            ],
            "AllowedHeaders": [
              "*"
            ],
            "ExposedHeaders": [
              "ETag"
            ],
            "MaxAge": 1800
          },
          "S3Write": {
            "AllowedOrigins": [
              "*"
            ],
            "AllowedMethods": [
              "PUT",
              "POST"
            ],
            "AllowedHeaders": [
              "Content-Length",
              "Content-Type",
              "Content-MD5",
              "Authorization",
              "Expect"
            ],
            "ExposedHeaders": [
              "ETag"
            ],
            "MaxAge": 1800
          },
          "S3Delete": {
            "AllowedOrigins": [
              "*"
            ],
            "AllowedMethods": [
              "DELETE"
            ],
            "AllowedHeaders": [
              "Content-Length",
              "Content-Type",
              "Content-MD5",
              "Authorization",
              "Expect"          ],
            "ExposedHeaders": [
              "ETag"
            ],
            "MaxAge": 1800
          }
        },
        "ScriptStores": {
          "_startup": {
            "Engine": "local",
            "Source": {
              "Directory": "$\\{GENERATION_STARTUP_DIR}/bootstrap"
            },
            "Destination": {
              "Prefix": "bootstrap"
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
            "blacklistedcountrycodes": [],
            "whitelistedcountrycodes": [],
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
          "blacklistips": {
            "Type": "IPMatch",
            "Description": "Blacklist IPs",
            "Filters": [
              {
                "Targets": [
                  "blacklistedips"
                ]
              }
            ]
          },
          "whitelistips": {
            "Type": "IPMatch",
            "Description": "Whitelist IPs",
            "Filters": [
              {
                "Targets": [
                  "whitelistedips"
                ]
              }
            ]
          },
          "blacklistcountries": {
            "Type": "GeoMatch",
            "Description": "Blacklist Countries",
            "Filters": [
              {
                "Targets": [
                  "blacklistedcountrycodes"
                ]
              }
            ]
          },
          "whitelistcountries": {
            "Type": "GeoMatch",
            "Description": "Whitelist Countries",
            "Filters": [
              {
                "Targets": [
                  "whitelistedcountrycodes"
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
          "blacklistips": {
            "Description": "Blacklist IPs",
            "NameSuffix": "blacklistips",
            "Conditions": [
              {
                "Condition": "blacklistips",
                "Negated": false
              }
            ]
          },
          "whitelistips": {
            "Description": "Whitelist IPs",
            "NameSuffix": "whitelistips",
            "Conditions": [
              {
                "Condition": "whitelistips",
                "Negated": false
              }
            ]
          },
          "blacklistcountries": {
            "Description": "Blacklist Countries",
            "NameSuffix": "blacklistcountries",
            "Conditions": [
              {
                "Condition": "blacklistcountries",
                "Negated": false
              }
            ]
          },
          "whitelistcountries": {
            "Description": "Whitelist Countries",
            "NameSuffix": "whitelistcountries",
            "Conditions": [
              {
                "Condition": "whitelistcountries",
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
              "network" : {
                "HTTPSProfile": "ELBSecurityPolicy-TLS-1-2-2017-01"
              },
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
              "CDNHTTPSProfile": "TLSv1",
              "GatewayHTTPSProfile" : "TLS_1_0",
              "ProtocolPolicy": "redirect-to-https",
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
            "es": {
              "ProtocolPolicy": "https-only"
            },
            "IPSecVPN" : {
              "IKEVersions" : [ "ikev1", "ikev2" ],
              "Rekey" : {
                "MarginTime" : 540,
                "FuzzPercentage" : 100
              },
              "ReplayWindowSize" : 1024,
              "DeadPeerDetectionTimeout" : 30,
              "Phase1" : {
                "EncryptionAlgorithms" : [ "AES256" ],
                "IntegrityAlgorithms" : [ "SHA2-256" ],
                "DiffeHellmanGroups" : [ 18, 22, 23, 24 ],
                "Lifetime" : 3600
              },
              "Phase2" : {
                "EncryptionAlgorithms" : [ "AES256" ],
                "IntegrityAlgorithms" : [ "SHA2-256" ],
                "DiffeHellmanGroups" : [ 18, 22, 23, 24 ],
                "Lifetime" : 3600
              }
            },
            "filetransfer" : {
              "EncryptionPolicy" : "TransferSecurityPolicy-2020-06"
            }
          }
        },
        "NetworkProfiles" :{
          "default" : {
            "BaseSecurityGroup" : {
              "Outbound" : {
                "GlobalAllow" : true,
                "NetworkRules" : {}
              }
            }
          }
        },
        "Bootstraps": {},
        "LoggingProfiles" : {
          "default" : {
            "ForwardingRules" : {}
          },
          "waf" : {
            "ForwardingRules" : {}
          }
        },
        "LogFilters": {
          "_all": {
            "Pattern": ""
          },
          "_pylog-critical": {
            "Pattern": "CRITICAL"
          },
          "_pylog-error": {
            "Pattern": "?CRITICAL ?ERROR"
          },
          "_pylog-warning": {
            "Pattern": "?CRITICAL ?ERROR ?WARNING"
          },
          "_pylog-info": {
            "Pattern": "?CRITICAL ?ERROR ?WARNING ?INFO"
          },
          "_pylog-debug": {
            "Pattern": "?CRITICAL ?ERROR ?WARNING ?INFO ?DEBUG"
          },
          "apache": {
            "Pattern": "[ip, id, user, timestamp, request, status_code=*, size]"
          },
          "_apache-4xx": {
            "Pattern": "[ip, id, user, timestamp, request, status_code=4*, size]"
          },
          "_apache-5xx": {
            "Pattern": "[ip, id, user, timestamp, request, status_code=5*, size]"
          }
        },
        "AlertRules" : {
          "All" : {
            "Severity" : "info",
            "Destinations" : {
              "Links" : {}
            }
          }
        },
        "AlertProfiles" : {
          "default" : {
            "Rules" : [ "All" ]
          }
        },
        "PlacementProfiles": {
          "external": {
            "default": {
              "Provider": "shared",
              "Region": "external",
              "DeploymentFramework": "default"
            }
          }
        },
        "DeploymentGroups" : {
          "segment" : {
            "Priority" : 10,
            "Level" : "segment",
            "ResourceSets" : {}
          },
          "solution" : {
            "Priority" : 100,
            "Level" : "solution",
            "ResourceSets" : {}
          },
          "application" : {
            "Priority" : 200,
            "Level" : "application",
            "ResourceSets" : {}
          }
        },
        "DeploymentModes" : {
          "_default" : {
            "Operations" : [ "update" ],
            "Membership" : "priority",
            "Priority" : {
              "GroupFilter" : ".*",
              "Order" : "LowestFirst"
            }
          },
          "update" : {
            "Operations" : [ "update" ],
            "Membership" : "priority",
            "Priority" : {
              "GroupFilter" : ".*",
              "Order" : "LowestFirst"
            }
          },
          "stop" : {
            "Operations" : [ "delete" ],
            "Membership" : "priority",
            "Priority" : {
              "GroupFilter" : ".*",
              "Order" : "HighestFirst"
            }
          },
          "stopstart" : {
            "Operations" : [ "delete", "update" ],
            "Membership" : "priority",
            "Priority" : {
              "GroupFilter" : ".*",
              "Order" : "LowestFirst"
            }
          }
        }
      }
  /]
[/#macro]
