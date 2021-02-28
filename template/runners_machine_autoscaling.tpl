%{ for config in runners_machine_autoscaling ~}
   [[runners.machine.autoscaling]]
    Periods = [${replace(format("\"%s\"", join("\",\"", config.periods)), "/\"{2,}/", "\"")}]
    IdleCount = ${config.idle_count}
    IdleTime = ${config.idle_time}
    Timezone = "${config.timezone}"
%{ endfor ~}
