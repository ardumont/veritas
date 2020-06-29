{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.veritas.configs.rofi;
in
{
  options.veritas.configs.rofi.enable = mkEnableOption "rofi configuration";

  config = mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      font = "Iosevka 12";
      terminal = "${pkgs.alacritty}/bin/alacritty";
      theme = "Arc-Dark";
    };
  };
}

# vim:foldmethod=marker:foldlevel=0:ts=2:sts=2:sw=2:et:nowrap
