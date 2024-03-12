{ config, pkgs, ... }:
let
  RTMP_PORT = 2463;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # nix basic settings
  nix.settings.experimental-features = [ "nix-command" ];
  nix.settings.auto-optimise-store = true;

  # non free packages
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" ];

  # power management
  powerManagement.enable = true; # "stock NixOS power management tool"
  services.thermald.enable = true; # "prevents overheating on intel cpus"
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PREF_POLICY_ON_AC = "performance";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;

      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PREF_POLICY_ON_BAT = "power";
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 80;

      START_CHARGE_THRESH_BAT0 = 83;
      STOP_CHARGE_THRESH_BAT0 = 89;

      START_CHARGE_THRESH_BAT1 = 83;
      STOP_CHARGE_THRESH_BAT1 = 89;
    };
  };

  services.tailscale.enable = true;
  services.avahi.enable = true;
  services.flatpak.enable = true;


  networking = {
    hostName = "yogakon";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 8000 RTMP_PORT ];
  };

  # hardware
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware = {

    pulseaudio.enable = true;
    bluetooth.enable = true;
  };

  virtualisation.docker.enable = true;

  services.blueman.enable = true;
  services.gnome.gnome-keyring.enable = true;
  # xserver settings
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "altgr-intl";
    libinput.enable = true;

    desktopManager = {
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };
    displayManager = {
      defaultSession = "xfce+i3";
      autoLogin = {
        enable = false;
      };
      lightdm = {
        enable = true;
        greeter.enable = true;
        greeters.slick.enable = true;
      };
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu #application launcher most people use
        i3status
        i3blocks #if you are planning on using i3blocks over i3status
      ];
    };
    videoDrivers = [ "amdgpu" ];

  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };


  environment.shells = [ pkgs.fish ];
  environment.pathsToLink = [ "/libexec" ];
  environment.systemPackages = with pkgs; [
    (
      let base = pkgs.appimageTools.defaultFhsEnvArgs; in
      pkgs.buildFHSUserEnv (base // {
        name = "fhs";
        targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [ pkgs.pkg-config ];
        profile = "export FHS=1";
        runScript = "fish";
        extraOutputsToInstall = [ "dev" ];
      })
    )
    gnumake
    i3
    htop
    killall
    libsecret
    moreutils
    nix-direnv
    nix-index
    nixpkgs-fmt
    p7zip
    rofi
    unzip
    vim-full
    wget
    xdotool
    yad
    zip
    google-chrome
    python3
    git
    git-absorb
    jq
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  time.timeZone = "America/Buenos_Aires";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };
  programs.fish.enable = true;

  users.defaultUserShell = pkgs.fish;
  users.users.baldosa = {
    useDefaultShell = true;
    isNormalUser = true; # home and stuff, not isSystemuser
    extraGroups = [ "wheel" ];
  };
  system.copySystemConfiguration = true;

  system.stateVersion = "23.11"; # Did you read the comment?
}

