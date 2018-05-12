[#case "filter"]
    [#-- DATA and QUERY credentials (USERNAME, PASSWORD) expected in env --]
    [#-- TODO(mfl): change container to use standard ES atributes --]
    [#assign es = component.Links["es"]]
    
    [@Attributes image="esfilter" /]
    
    [@Variables
        {
            "CONFIGURATION" : appsettings?json_string,
            "ES" :
                getReference(
                    formatElasticSearchId(
                        es.Tier,
                        es.Component),
                    DNS_ATTRIBUTE_TYPE) + ":443"        }
    /]
            
    [#break]

