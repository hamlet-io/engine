[#-- Dashboard --]

[#if componentType == "dashboard"]

    [#if deploymentSubsetRequired("dashboard", true)]
        [@createDashboard
            mode=segmentListMode
            id=formatSegmentCWDashboardId()
            name=formatSegmentFullName()
            components=dashboardComponents
        /]
    [/#if]
[/#if]


