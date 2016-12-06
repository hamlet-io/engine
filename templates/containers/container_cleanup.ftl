[#case "cleanup"]
    [#switch containerListMode]
        [#case "definition"]
            "Name" : "${tier.Name + "-" + component.Name + "-" + container.Name}",
            "Image" : "${docker.Registry}/cleanup${dockerTag}",
            "Environment" : [
                {
                    "Name" : "CLEAN_PERIOD",
                    "Value" : "900"
                },
                {
                    "Name" : "DELAY_TIME",
                    "Value" : "10800"
                }
            ],
            "MountPoints": [
                {
                    "SourceVolume": "dockerDaemon",
                    "ContainerPath": "/var/run/docker.sock",
                    "ReadOnly": false
                },
                {
                    "SourceVolume": "dockerFiles",
                    "ContainerPath": "/var/lib/docker",
                    "ReadOnly": false
                }
            ],
            "Essential" : true,
            [#break]

        [#case "volumeCount"]
            [#assign volumeCount += 2]
            [#break]

        [#case "volumes"]
            [#if volumeCount > 0],[/#if]
            {
                "Host": {
                    "SourcePath": "/var/run/docker.sock"
                },
                "Name": "dockerDaemon"
            },
            {
                "Host": {
                    "SourcePath": "/var/lib/docker"
                },
                "Name": "dockerFiles"
            }
            [#assign volumeCount += 2]
            [#break]

    [/#switch]
    [#break]

