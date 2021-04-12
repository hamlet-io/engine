[#ftl]

[#assign COMPUTE_TASK_GENERAL_TASK = "general_task" ]
[@addComputeTask
    type=COMPUTE_TASK_GENERAL_TASK
    properties=[
        {
            "Type"  : "Description",
            "Value" : "A general task for user level configuration"
        }
    ]
/]

[#assign COMPUTE_TASK_RUN_STARTUP_CONFIG = "run_startup_config" ]
[@addComputeTask
    type=COMPUTE_TASK_RUN_STARTUP_CONFIG
    properties=[
        {
            "Type" : "Description",
            "Value" : "Run the process which will setup and execute the startup configuration process"
        }
    ]
/]

[#assign COMPUTE_TASK_HAMLET_ENVIRONMENT_VARIABLES = "hamlet_env_var" ]
[@addComputeTask
    type=COMPUTE_TASK_HAMLET_ENVIRONMENT_VARIABLES
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Add hamlet settings as environment varaibles available as part of the default user shell"
        }
    ]
/]

[#assign COMPUTE_TASK_OS_SECURITY_PATCHING = "os_security_patching" ]
[@addComputeTask
    type=COMPUTE_TASK_OS_SECURITY_PATCHING
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Enable a scheduled process to apply OS level security patching"
        }
    ]
/]

[#assign COMPUTE_TASK_SYSTEM_LOG_FORWARDING = "system_log_forwarding" ]
[@addComputeTask
    type=COMPUTE_TASK_SYSTEM_LOG_FORWARDING
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Enable forwarding of system log events to a standard log store"
        }
    ]
/]

[#assign COMPUTE_TASK_FILE_DIR_CREATION = "file_dir_create" ]
[@addComputeTask
    type=COMPUTE_TASK_FILE_DIR_CREATION
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Create files and directories as part of system startup"
        }
    ]
/]

[#assign COMPUTE_TASK_DATA_VOLUME_MOUNTING = "data_volume_mounting" ]
[@addComputeTask
    type=COMPUTE_TASK_DATA_VOLUME_MOUNTING
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Handle the discovery, formatting and mounting of data volumes"
        }
    ]
/]

[#assign COMPUTE_TASK_USER_ACCESS = "user_access" ]
[@addComputeTask
    type=COMPUTE_TASK_USER_ACCESS
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Update the default account to include access for links to user components"
        }
    ]
/]

[#assign COMPUTE_TASK_RUN_SCRIPTS_DEPLOYMENT = "run_scripts_deployment" ]
[@addComputeTask
    type=COMPUTE_TASK_RUN_SCRIPTS_DEPLOYMENT
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Retrive and execute a scripts.zip image stored in the scripts registry"
        }
    ]
/]

[#assign COMPUTE_TASK_EFS_MOUNT = "efs_mount" ]
[@addComputeTask
    type=COMPUTE_TASK_EFS_MOUNT
    properties=[
        {
            "Type" : "Description",
            "Value" : "Find and configure mounts for links to efs components"
        }
    ]
/]

[#assign COMPUTE_TASK_USER_BOOTSTRAP = "user_bootstrap" ]
[@addComputeTask
    type=COMPUTE_TASK_USER_BOOTSTRAP
    properties=[
        {
            "Type" : "Description",
            "Value" : "Run tasks provided through Bootstraps defined in the solution"
        }
    ]
/]
