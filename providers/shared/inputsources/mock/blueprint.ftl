[#ftl]

[#-- Intial seeding of settings data based on input data --]
[#macro shared_input_mock_blueprint_seed ]
    [@addBlueprint
        blueprint=
        {
            "Tenant": {
                "Id": "mockten",
                "CertificateBehaviours": {
                    "External": true
                }
            },
            "Account": {
                "Region": "mock-region-1",
                "Domain": "mock",
                "Audit": {
                    "Offline": 90,
                    "Expiration": 2555
                },
                "Id": "mockacct",
                "Seed": "abc123",
                "AWSId": "0123456789"
            },
            "Product": {
                "Id": "mockedup",
                "Region": "mock-region-1",
                "Domain": "mockedup",
                "Profiles": {
                    "Placement": "default"
                }
            },
            "Environment": {
                "Id": "int",
                "Name": "integration"
            },
            "Segment": {
                "Id": "default",
                "Bastion": {
                    "Active": false
                },
                "ConsoleOnly": true,
                "multiAZ": true
            },
            "IPAddressGroups": {},
            "Domains": {
                "Validation": "mock.local",
                "mockdomain": {
                    "Stem": "mock.local"
                }
            },
            "Certificates": {
                "mockedup": {
                    "Domain": "mockdomain"
                }
            },
            "Solution": {
                "Id": "mockapp"
            }
        }
    /]
[/#macro]
