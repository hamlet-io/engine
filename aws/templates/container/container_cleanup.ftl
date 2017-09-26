[#case "cleanup"]
    [@Attributes image="cleanup" /]

    [@Variables
        {
            "CLEAN_PERIOD" : "900",
            "DELAY_TIME" : "10800"
        }
    /]
    
    [@Volume "dockerDaemon" "/var/run/docker.sock" "/var/run/docker.sock" /]
    [@Volume "dockerFiles" "/var/lib/docker" "/var/lib/docker" /]

    [#break]

