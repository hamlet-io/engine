[#ftl]

[#-- Shared Resource labels used for all providers --]
[#assign RESOURCE_LABEL_COMPONENT = "component" ]

[@addResourceLabel
    label=RESOURCE_LABEL_COMPONENT
    description="Standard component resources"
    levels="*"
    subsets=[ "_component" ]
/]
