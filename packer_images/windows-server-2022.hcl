packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "password" {
  type      = string
  sensitive = true
  default   = "SuperS3cr3t!!!"
}

variable "runner_version" {
  type    = string
  default = "18.0.0"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "docker" {
  ami_name              = "windows-server-2022-runners-${local.timestamp}"
  force_deregister      = true
  force_delete_snapshot = true
  region                = "eu-west-1"
  ebs_optimized         = true
  encrypt_boot          = true
  instance_type         = "c7a.2xlarge"
  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Core-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  tags = {
    runner_version = "${var.runner_version}"
  }

  aws_polling {
    delay_seconds = 60
    max_attempts  = 60
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 50
    volume_type           = "gp2"
    delete_on_termination = true
  }

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = "${var.password}"
  winrm_use_ssl  = false
  winrm_insecure = true

  # This user data file sets up winrm and configures it so that the connection
  # from Packer is allowed. Without this file being set, Packer will not
  # connect to the instance.
  user_data = <<-EOT
  <powershell>
  # Set administrator password
  net user Administrator ${var.password}
  wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE

  # First, make sure WinRM can't be connected to
  netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=block

  # Delete any existing WinRM listeners
  winrm delete winrm/config/listener?Address=*+Transport=HTTP  2>$Null
  winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

  # Disable group policies which block basic authentication and unencrypted login

  Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client -Name AllowBasic -Value 1
  Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client -Name AllowUnencryptedTraffic -Value 1
  Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service -Name AllowBasic -Value 1
  Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service -Name AllowUnencryptedTraffic -Value 1

  # Create a new WinRM listener and configure
  winrm create winrm/config/listener?Address=*+Transport=HTTP
  winrm set winrm/config '@{MaxTimeoutms="7200000"}'
  winrm set winrm/config '@{MaxEnvelopeSizekb="8192"}'
  winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
  winrm set winrm/config/winrs '@{MaxProcessesPerShell="0"}'
  winrm set winrm/config/service '@{AllowUnencrypted="true"}'
  winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
  winrm set winrm/config/service/auth '@{Basic="true"}'
  winrm set winrm/config/client/auth '@{Basic="true"}'

  # Configure UAC to allow privilege elevation in remote shells
  $Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
  $Setting = 'LocalAccountTokenFilterPolicy'
  Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

  # Configure and restart the WinRM Service; Enable the required firewall exception
  Stop-Service -Name WinRM
  Set-Service -Name WinRM -StartupType Automatic
  netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=allow localip=any remoteip=any
  Start-Service -Name WinRM
  </powershell>
  EOT
}

build {
  sources = ["source.amazon-ebs.docker"]

  provisioner "powershell" {
    inline = [
      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
    ]
  }

  # install containers feature
  provisioner "powershell" {
    inline = [
      "choco feature enable -n allowGlobalConfirmation",
      "choco install git",
      "choco install Containers Microsoft-Hyper-V --source windowsfeatures",
    ]

    valid_exit_codes = [0, 3010]
  }

  # restart is needed for the containers windows feature
  provisioner "windows-restart" {}

  # install docker-engine
  provisioner "powershell" {
    inline = [
      "choco install docker-engine --version=27.4.1",
    ]
  }

  # Administrator is added to docker-users group, we restart for this to work
  provisioner "windows-restart" {}

  # pre-bake some images to reduce pull time during job execution
  provisioner "powershell" {
    inline = [
      "docker pull mcr.microsoft.com/windows/servercore:ltsc2022",
      "docker pull registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v${var.runner_version}-servercore21H2",
    ]
  }

  provisioner "powershell" {
    inline = [
      "& 'C:\\Program Files\\Amazon\\EC2Launch\\ec2launch.exe' sysprep --shutdown=true --clean=true"
    ]
  }
}