[#case "www"]
[#case "wwwtask"]
    [#switch containerListMode]
        [#case "definition"]
            "Name" : "${tier.Name + "-" + component.Name + "-" + container.Id}",
            "Image" : "${docker.Registry}/${productId}/${slice}-${buildCommit}${dockerTag}",
            "Environment" : [
                [@standardEnvironmentVariables /]
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

