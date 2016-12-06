[#case "mongodb"]
    [#switch containerListMode]
        [#case "definition"]
            "Name" : "${tier.Name + "-" + component.Name + "-" + container.Name}",
            "Image" : "${docker.Registry}/mongodb${dockerTag}",
            "MountPoints": [
                {
                    "SourceVolume": "mongodb",
                    "ContainerPath": "/data/db",
                    "ReadOnly": false
                }
            ],
            "Essential" : true,
            [#break]

        [#case "volumeCount"]
            [#assign volumeCount += 1]
            [#break]

        [#case "volumes"]
            [#if volumeCount > 0],[/#if]
            {
                "Host": {
                    "SourcePath": "/product/mongodb/db"
                },
                "Name": "mongodb"
            }
            [#assign volumeCount += 1]
            [#break]

    [/#switch]
    [#break]

