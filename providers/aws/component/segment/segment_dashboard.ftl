[#-- Dashboard --]

[#if componentType == "dashboard"]

    [#if deploymentSubsetRequired("dashboard", true)]
        [@createDashboard
            mode=listMode
            id=formatSegmentCWDashboardId()
            name=formatSegmentFullName()
            components=dashboardComponents
        /]
    [/#if]
[/#if]


