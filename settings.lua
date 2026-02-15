-- Runtime mod setting: redirect construction robots to nearest storage after mining
data:extend{
  {
    type = "bool-setting",
    name = "robots-configurable-behavior-redirect-to-nearest-storage",
    setting_type = "runtime-global",
    default_value = true,
    order = "a"
  }
}
