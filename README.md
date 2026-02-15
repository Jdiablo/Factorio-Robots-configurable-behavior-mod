The mod to customize robots (construction\logistic drone) behavior in Factorio.

For now it has only one feature: *redirect mined items to nearest storage*. When the construction robot is about to mine (delete via ALT+D hotkey) some enitity - the robot will move it to the nearest chest instead of going to another chest with the same enitity in stack but in a far distance. Techically under the hood the mod just adds the same temporary entity (if not exists) to the nearest chest when the robot is about to mine the entity (robot will choose this chest by prioritization because it's already filled with the same entity) and then removes it in short time.

# Installation
1. Copy all files to your Factorio mods directory.
2. Enable the mod in the main menu settings
3. Enable the mod during the game in pause menu (ESC -> Mod settings -> Checkbox)