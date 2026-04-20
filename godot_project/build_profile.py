# Build target
target = "template_release"
debug_symbols = "no"

# Size optimization — web already defaults to optimize=size,
# but lto=full gives extra gains (~3MB saved on web)
optimize = "size_extra"
lto = "full"               # Warning: adds ~5-15min to build time

# Strip 3D entirely (~10MB saved on web)
disable_3d = "yes"

# Strip advanced GUI nodes (RichTextLabel, SpinBox, TextEdit, etc.)
# Only use if your game doesn't need them
disable_advanced_gui = "yes"

# Use the lightweight fallback text server instead of the full ICU one
# Only safe if your game is Latin/English script — no RTL, no ligatures
module_text_server_adv_enabled = "no"
module_text_server_fb_enabled = "yes"

# Disable renderers not used on web (web only uses Compatibility/OpenGL)
vulkan = "no"
use_volk = "no"
openxr = "no"

# Disable misc features
deprecated = "no"
minizip = "no"
graphite="no"    # Disables SIL Graphite smart fonts support

# Disable ALL modules by default, then re-enable only what you need
modules_enabled_by_default = "no"
module_gdscript_enabled = "yes"
module_freetype_enabled = "yes"       # required for text rendering
module_text_server_fb_enabled = "yes" # required for text rendering
module_svg_enabled = "yes"            # required for SVG icons/fonts
module_webp_enabled = "yes"           # required for WebP textures
module_godot_physics_2d_enabled = "yes"  # if you use 2D physics
# module_godot_physics_2d_enabled = "no"  # if you use NO physics at all

# Disable navigation (already in your gdbuild, but belt-and-suspenders)
disable_navigation_2d = "yes"
disable_navigation_3d = "yes"
disable_xr = "yes"