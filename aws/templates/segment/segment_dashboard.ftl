[#-- Dashboard --]

[#if componentType == "dashboard"]
    [@createDashboard
        mode=segmentListMode
        id=formatSegmentCWDashboardId()
        name=formatSegmentFullName()
        components=dashboardComponents
    /]
[/#if]


