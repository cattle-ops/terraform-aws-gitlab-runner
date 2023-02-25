%{~ for config in runners_machine_autoscaling ~}
    [[runners.machine.autoscaling]]
    %{~ for key, value in config ~}
      %{ if key == "Periods" }Periods = [${replace(format("\"%s\"", join("\",\"", value)), "/\"{2,}/", "\"")}]%{ else }
      ${key} = ${ can(tonumber(value)) ? value : format("\"%s\"", value)}
      %{~ endif ~}
      %{~ endfor ~}
%{~ endfor ~}
