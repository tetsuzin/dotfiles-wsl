{ lazyvimStarter, ... }:

{
  xdg.configFile = {
    "nvim/".source = "${lazyvimStarter}/";
  };
}
