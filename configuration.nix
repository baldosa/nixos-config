{ config, pkgs, ... }:
let
  RTMP_PORT = 2463;
in
{
    imports = [
        ./hardware-configuration.nix
        <home-manager/nixos>
    ];

    # nix basic settings
    nix.settings.experimental-features = [ "nix-command" ];
    nix.settings.auto-optimise-store = true;
    
    # non free packages
    nixpkgs.config.allowUnfree = true;


    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # power management
    powerManagement.enable = true;    # "stock NixOS power management tool"
    services.thermald.enable = true;  # "prevents overheating on intel cpus"
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
        STOP_CHARGE_THRESH_BAT0  = 89;

        START_CHARGE_THRESH_BAT1 = 83;
        STOP_CHARGE_THRESH_BAT1  = 89;
      };
    };

    services.tailscale.enable = true;
    services.avahi.enable = true;

    services.flatpak.enable = true;
    
    
    networking = {
      hostName = "LOLI";
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

      nvidia = {
        # Modesetting is required.
        modesetting.enable = true;

        # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
        powerManagement.enable = false;
        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        powerManagement.finegrained = false;

        # Use the NVidia open source kernel module (not to be confused with the
        # independent third-party "nouveau" open source driver).
        # Support is limited to the Turing and later architectures. Full list of
        # supported GPUs is at:
        # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
        # Only available from driver 515.43.04+
        # Do not disable this unless your GPU is unsupported or if you have a good reason to.
        # open = true;

        # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
        nvidiaSettings = true;

        # Optionally, you may need to select the appropriate driver version for your specific GPU.
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      pulseaudio.enable = true;
      bluetooth.enable = true;
    };


    # services.blueman.enable = true;

    # xserver settings
    services.xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "altgr-intl";
      libinput.enable = true;

      desktopManager.xfce.enable = true;
      
      displayManager = {
        defaultSession = "none+i3";
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
          i3status # gives you the default i3 status bar
          i3lock #default i3 screen locker
          i3blocks #if you are planning on using i3blocks over i3status
        ];
      };
      videoDrivers = ["nvidia"];   

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
        (let base = pkgs.appimageTools.defaultFhsEnvArgs; in 
            pkgs.buildFHSUserEnv (base // {
              name = "fhs";
              targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [pkgs.pkg-config]; 
              profile = "export FHS=1"; 
              runScript = "fish"; 
              extraOutputsToInstall = ["dev"]; }))
    
        ((vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: rec {
          src = (builtins.fetchTarball {
            url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
            sha256 = "09dykbnlm0r7317iv03dpi9f1vxxy6l8lagf6ssaqa2rbxly5zy4";
          });
          version = "latest";

          buildInputs = oldAttrs.buildInputs ++ [ pkgs.krb5 ];
        })).fhs
        alacritty
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
    ];
    

    environment.variables = {
      EDITOR = "vim";
      MOZ_USE_XINPUT2 = "1";
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

    fonts.packages = with pkgs; [
        iosevka
        terminus_font_ttf
    ];

    users.defaultUserShell = pkgs.fish;
    users.users.baldosa = {
        useDefaultShell = true;
        isNormalUser = true;  # home and stuff, not isSystemuser
        extraGroups = [ "wheel" ];
        packages = with pkgs; [
            git
            git-absorb
            jq
            python3
        ];
        
    };


    system.copySystemConfiguration = true;

    system.stateVersion = "23.11"; # Did you read the comment?
}

