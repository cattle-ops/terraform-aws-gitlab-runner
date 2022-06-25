disable_cache = %{if disable_cache != null} ${disable_cache} %{else} false %{endif}
image         = %{if image != null} ${image} %{else} "docker:18.03.1-ce" %{endif}
privileged    = %{if privileged != null} ${privileged} %{else} true %{endif}
pull_policy   = %{if pull_policy != null} ${pull_policy} %{else} "always" %{endif}
shm_size      = %{if shm_size != null} ${shm_size} %{else} 0 %{endif}
tls_verify    = %{if tls_verify != null} ${tls_verify} %{else} false %{endif}
volumes       = %{if volumes != null} [${volumes}] %{else} ["/cache"] %{endif}

allowed_images               = list(string)
allowed_pull_policies        = list(string)
allowed_services             = list(string)
%{ if cache_dir != null } cache_dir = "${cache_dir}" %{endif}
cap_add                      = list(string)
cap_drop                     = list(string)
container_labels             = list(string)
%{ if cpuset_cpus != null } cpuset_cpus = "${cpuset_cpus}" %{endif}
%{ if cpu_shares != null } cpu_shares = ${cpu_shares} %{endif}
%{ if cpus != null } cpus = ${cpus} %{endif}
devices                      = list(string)
device_cgroup_rules          = list(string)
%{ if disable_entrypoint_overwrite != null } disable_entrypoint_overwrite = ${disable_entrypoint_overwrite} %{endif}
dns                          = list(string)
dns_search                   = list(string)
extra_hosts                  = list(string)
%{ if gpus != null } gpus = "${gpus}" %{endif}
%{ if helper_image != null } helper_image = "${helper_image}" %{endif}
%{ if helper_image_flavor != null } helper_image_flavor = "${helper_image_flavor}" %{endif}
%{ if host != null } host = "${host}" %{endif}
%{ if hostname != null } hostname = "${hostname}" %{endif}
links                        = list(string)
%{ if memory != null } memory = "${memory}" %{endif}
%{ if memory_reservation != null } memory_reservation = "${memory_reservation}" %{endif}
%{ if memory_swap != null } memory_swap = "${memory_swap}" %{endif}
%{ if network_mode != null } network_mode = "${network_mode}" %{endif}
%{ if oom_kill_disable != null } oom_kill_disable = ${oom_kill_disable} %{endif}
%{ if oom_score_adjust != null } oom_score_adjust = ${oom_score_adjust} %{endif}
%{ if runtime != null } runtime = "${runtime} %{endif}"
security_opt                 = list(string)
sysctls                      = list(string)
%{ if tls_cert_path != null } tls_cert_path = "${tls_cert_path}" %{endif}
%{ if userns_mode != null } userns_mode = "${userns_mode}" %{endif}
volumes_from                 = list(string)
%{ if volume_driver != null } volume_driver = "${volume_driver}" %{endif}
%{ if wait_for_services_timeout != null } wait_for_services_timeout = ${wait_for_services_timeout} %{endif}