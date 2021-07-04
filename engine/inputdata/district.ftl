[#ftl]

[#-----------------------------------------------
-- Public functions for district configuration --
-------------------------------------------------]

[#assign districtConfiguration = {} ]

[#-- Macros to assemble the district configuration --]
[#macro addDistrict type layers properties=[]  ]
    [#local configuration =
        {
            "Type" : type,
            "Properties" : asArray(properties),
            "Layers" : asArray(layers)
        }
    ]

    [#-- Ensure the porvided layers are configured --]
    [#list configuration.Layers as layer]
        [#if ! isLayerConfigured(layer)]
            [@fatal
                message="Unknown layer in " + type + " district configuration"
                context=configuration
                detail=layer
            /]
        [/#if]
    [/#list]

    [#assign districtConfiguration =
        mergeObjects(
            districtConfiguration,
            {
                type : configuration
            }
        )
    ]
[/#macro]

[#-------------------------------------------------------
-- Internal support functions for component processing --
---------------------------------------------------------]
