[#ftl]

[@addComponent
    type=ECS_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An autoscaling container host cluster"
            }
        ]
    attributes=containerHostAttributes
/]

[@addComponentDeployment
    type=ECS_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addChildComponent
    type=ECS_SERVICE_COMPONENT_TYPE
    parent=ECS_COMPONENT_TYPE
    childAttribute="Services"
    linkAttributes="Service"
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An orchestrated container with always on scheduling"
            }
        ]
    attributes=containerServiceAttributes
/]

[@addComponentDeployment
    type=ECS_SERVICE_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addChildComponent
    type=ECS_TASK_COMPONENT_TYPE
    parent=ECS_COMPONENT_TYPE
    childAttribute="Tasks"
    linkAttributes="Task"
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A container defintion which is invoked on demand"
            }
        ]
    attributes=containerTaskAttributes
/]

[@addComponentDeployment
    type=ECS_TASK_COMPONENT_TYPE
    defaultGroup="application"
/]
