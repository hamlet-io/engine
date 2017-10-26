[#case "redirector"]
    [#switch containerListMode]
        [#case "definition"]
            [@containerBasicAttributes
                containerName
                "redirector" + dockerTag
            /]
            [#break]

        [#case "environmentCount"]
        [#case "environment"]
        [#case "volumeCount"]
        [#case "volumes"]
        [#case "mountPointCount"]
        [#case "mountPoints"]
    [/#switch]
    [#break]
