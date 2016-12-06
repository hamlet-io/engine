[#case "provider"]
    [#switch containerListMode]
        [#case "definition"]
            "Name" : "${tier.Name + "-" + component.Name + "-" + container.Id}",
            "Image" : "${docker.Registry}/${projectId}/${slice}-${buildCommit}",
            "Environment" : [
                [@standardEnvironmentVariables /]
                {
                    "Name" : "NODE_ENV",
                    "Value" : "${environmentName}"
                },
                {
                    "Name" : "CONFIGURATION",
                    "Value" : "${configuration?json_string}"
                },
                {
                    "Name" : "REGION",
                    "Value" : "${regionId}"
                },
                {
                    "Name" : "KEYID",
                    "Value" : "${getKey("cmkXsegmentXcmk")}"
                },
                {
                    "Name" : "S3_PREFIX",
                    "Value" : "${container.Id}"
                },
                {
                    "Name" : "S3_BUCKET",
                    "Value" : "${logsBucket}"
                },
                {
                    "Name" : "ES_HOST",
                    "Value" : "${"https://" + getKey("esXanaXesXdns")}"
                }
            ],
            "Essential" : true,
            [#break]

        [#case "volumeCount"]
            [#break]

        [#case "volumes"]
            [#break]

        [#case "supplemental"]
            [#break]

    [/#switch]
    [#break]

