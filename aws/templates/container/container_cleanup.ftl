[#case "cleanup"]
    [#switch containerListMode]
        [#case "definition"]
            [@containerBasicAttributes
                containerName
                "cleanup" + dockerTag
            /]
            [#break]

        [#case "environmentCount"]
        [#case "environment"]
            [@environmentVariable
                "CLEAN_PERIOD" "900"
                containerListTarget containerListMode/]
            [@environmentVariable
                "DELAY_TIME" "10800"
                containerListTarget containerListMode/]
            [#break]

        [#case "volumeCount"]
        [#case "volumes"]
        [#case "mountPointCount"]
        [#case "mountPoints"]
            [@containerVolume
                "dockerDaemon"
                "/var/run/docker.sock"
                "/var/run/docker.sock" /]
            [@containerVolume
                "dockerFiles"
                "/var/lib/docker"
                "/var/lib/docker" /]
            [#break]

    [/#switch]
    [#break]

