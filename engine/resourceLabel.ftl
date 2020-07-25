[#ftl]

[#-- tasks are executed in contracts --]
[#-- Each task should perform a specifc action to manage a deployment --]

[#assign resourceLabelConfiguration = {}]

[#-- Macros to assemble the component configuration --]
[#macro addResourceLabel label description levels subsets ]
    [#list asArray(levels)  as level ]
        [@internalMergeResourceLabelConfiguration
            label=label
            level=level
            configuration=
                {
                    "Description" : description,
                    "Subsets" : asArray(subsets)
                }
        /]
    [/#list]
[/#macro]

[#function getResourceLabel label level ]

    [#if ((resourceLabelConfiguration[label][level])!{})?has_content]
        [#local resourceLabelConfig = (resourceLabelConfiguration[label][level])!{} ]
    [#else]
        [#local resourceLabelConfig = (resourceLabelConfiguration[label]["*"])!{} ]
    [/#if]

    [#if ! resourceLabelConfig?has_content ]
        [@fatal
            message="Could not find resource label"
            detail=label
        /]
    [/#if]

    [#return resourceLabelConfig ]
[/#function]

[#-------------------------------------------------------
-- Internal support functions for task processing      --
---------------------------------------------------------]

[#-- Helper macro - not for general use --]
[#macro internalMergeResourceLabelConfiguration label level configuration]
    [#assign resourceLabelConfiguration =
        mergeObjects(
            resourceLabelConfiguration,
            {
                label : {
                    level : configuration
                }
            }
        )]
[/#macro]
