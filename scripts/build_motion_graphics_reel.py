import os
import sys

# Configure environment for DaVinci Resolve Scripting
os.environ['RESOLVE_SCRIPT_API'] = r'C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting'
os.environ['RESOLVE_SCRIPT_LIB'] = r'C:\Program Files\Blackmagic Design\DaVinci Resolve\fusionscript.dll'
os.environ['PYTHONPATH'] = r'C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting\Modules;' + os.environ.get('PYTHONPATH', '')
try:
    os.add_dll_directory(r'C:\Program Files\Blackmagic Design\DaVinci Resolve')
except Exception:
    pass
sys.path.append(r'C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting\Modules')

import DaVinciResolveScript as dvr_script

resolve = dvr_script.scriptapp("Resolve")
if not resolve:
    print("FATAL: Could not connect to DaVinci Resolve.")
    sys.exit(1)

print(f"Connected to DaVinci Resolve {resolve.GetVersionString()}")

projectManager = resolve.GetProjectManager()
project = projectManager.GetCurrentProject()
if not project:
    print("FATAL: No project open.")
    sys.exit(1)

print(f"Active Project: {project.GetName()}")
mediaPool = project.GetMediaPool()

ASSETS_DIR = r"C:\Users\kouek\kouekam\business\familytree\motion_assets"

HERO_IMG = os.path.join(ASSETS_DIR, "branding_1_landing_hero.png")
CREST_IMG = os.path.join(ASSETS_DIR, "app_icon_badge.png")
PHONE_REGISTRY = os.path.join(ASSETS_DIR, "device_samsung_galaxy_perfect.png")
PHONE_TREE = os.path.join(ASSETS_DIR, "live_device_screen_tree.png")
TREE_IMG = os.path.join(ASSETS_DIR, "suite_2_tree_canvas.png")
KINSHIP_IMG = os.path.join(ASSETS_DIR, "suite_4_kinship_solver.png")
ALLIANCES_IMG = os.path.join(ASSETS_DIR, "suite_5_royal_alliances.png")
SIDEBAR_IMG = os.path.join(ASSETS_DIR, "branding_3_authenticated_sidebar.png")
AUDIO_FILE = os.path.join(ASSETS_DIR, "kkevo_motion_soundtrack.wav")

TIMELINE_NAME = "KKEVO_DYNASTY_OFFICIAL_MOTION_GRAPHICS"

# 1. Setup or recreate timeline
existing_tl = None
for i in range(1, project.GetTimelineCount() + 1):
    tl = project.GetTimelineByIndex(i)
    if tl and tl.GetName() == TIMELINE_NAME:
        existing_tl = tl
        break

if existing_tl:
    print(f"Activating timeline: {TIMELINE_NAME}")
    project.SetCurrentTimeline(existing_tl)
    timeline = existing_tl
else:
    print(f"Creating timeline: {TIMELINE_NAME}")
    timeline = mediaPool.CreateEmptyTimeline(TIMELINE_NAME)
    project.SetCurrentTimeline(timeline)

resolve.OpenPage("edit")

# Ensure 6 video clips
items = [it for it in timeline.GetItemListInTrack("video", 1) if it.GetFusionCompCount() > 0]
current_count = len(items)
print(f"Current video clip count: {current_count}")

while current_count < 6:
    items = [it for it in timeline.GetItemListInTrack("video", 1) if it.GetFusionCompCount() > 0]
    if items and len(items) > 0:
        last_end = items[-1].GetEnd()
        hours = last_end // (3600 * 24)
        rem = last_end % (3600 * 24)
        mins = rem // (60 * 24)
        rem = rem % (60 * 24)
        secs = rem // 24
        frames = rem % 24
        tc = f"{hours:02d}:{mins:02d}:{secs:02d}:{frames:02d}"
        timeline.SetCurrentTimecode(tc)
    timeline.InsertFusionCompositionIntoTimeline()
    current_count += 1
    print(f"Inserted clip {current_count}/6")

items = [it for it in timeline.GetItemListInTrack("video", 1) if it.GetFusionCompCount() > 0]
print(f"Active with {len(items)} video clips.")


# -------------------------------------------------------------
# ROBUST FUSION BUILDER HELPERS
# -------------------------------------------------------------

def clean_comp(comp):
    for tool in list(comp.GetToolList().values()):
        if tool.GetAttrs("TOOLS_RegID") != "MediaOut":
            tool.Delete()
    for tool in comp.GetToolList().values():
        if tool.GetAttrs("TOOLS_RegID") == "MediaOut":
            return tool
    return comp.AddTool("MediaOut")

def create_ambient_background(comp):
    # Pure dark obsidian space navy
    bg = comp.AddTool("Background")
    bg.Type = "Solid"
    bg.TopLeftRed = 0.016
    bg.TopLeftGreen = 0.022
    bg.TopLeftBlue = 0.042
    bg.TopLeftAlpha = 1.0
    
    # Ambient gold stardust
    noise = comp.AddTool("FastNoise")
    noise.Detail = 3.2
    noise.Contrast = 1.5
    noise.Brightness = -0.34
    noise.XScale = 24.0
    noise.SeetheRate = 0.06
    
    gold_tint = comp.AddTool("Background")
    gold_tint.TopLeftRed = 0.90
    gold_tint.TopLeftGreen = 0.72
    gold_tint.TopLeftBlue = 0.25
    gold_tint.TopLeftAlpha = 1.0
    
    noise_m = comp.AddTool("Merge")
    noise_m.Background.ConnectTo(gold_tint.Output)
    noise_m.Foreground.ConnectTo(noise.Output)
    noise_m.ApplyMode = "Multiply"
    
    bg_m = comp.AddTool("Merge")
    bg_m.Background.ConnectTo(bg.Output)
    bg_m.Foreground.ConnectTo(noise_m.Output)
    bg_m.Blend = 0.07
    return bg_m

def create_hud_badge(comp, title, subtitle, center, width=0.36, height=0.078):
    # Dark glass backplate
    g_bg = comp.AddTool("Background")
    g_bg.TopLeftRed = 0.03
    g_bg.TopLeftGreen = 0.05
    g_bg.TopLeftBlue = 0.11
    g_bg.TopLeftAlpha = 0.92
    
    g_mask = comp.AddTool("RectangleMask")
    g_mask.Width = width
    g_mask.Height = height
    g_mask.CornerRadius = 0.02
    g_mask.Center = center
    
    g_m = comp.AddTool("Merge")
    g_m.Foreground.ConnectTo(g_bg.Output)
    g_m.EffectMask.ConnectTo(g_mask.Mask)
    
    # Gold border
    b_bg = comp.AddTool("Background")
    b_bg.TopLeftRed = 0.92
    b_bg.TopLeftGreen = 0.76
    b_bg.TopLeftBlue = 0.26
    b_bg.TopLeftAlpha = 1.0
    
    b_mask = comp.AddTool("RectangleMask")
    b_mask.Width = width
    b_mask.Height = height
    b_mask.CornerRadius = 0.02
    b_mask.BorderWidth = 0.002
    b_mask.Solid = 0
    b_mask.Center = center
    
    b_m = comp.AddTool("Merge")
    b_m.Background.ConnectTo(g_m.Output)
    b_m.Foreground.ConnectTo(b_bg.Output)
    b_m.EffectMask.ConnectTo(b_mask.Mask)
    
    # Title Text
    t_title = comp.AddTool("TextPlus")
    t_title.StyledText = title
    t_title.Size = 0.021
    t_title.Center = [center[0], center[1] + 0.016]
    t_title.Red1 = 0.96
    t_title.Green1 = 0.82
    t_title.Blue1 = 0.28
    
    # Subtitle Text
    t_sub = comp.AddTool("TextPlus")
    t_sub.StyledText = subtitle
    t_sub.Size = 0.014
    t_sub.Center = [center[0], center[1] - 0.015]
    t_sub.Red1 = 0.82
    t_sub.Green1 = 0.90
    t_sub.Blue1 = 0.98
    
    m_t = comp.AddTool("Merge")
    m_t.Background.ConnectTo(b_m.Output)
    m_t.Foreground.ConnectTo(t_title.Output)
    
    m_s = comp.AddTool("Merge")
    m_s.Background.ConnectTo(m_t.Output)
    m_s.Foreground.ConnectTo(t_sub.Output)
    return m_s

def create_scene_header(comp, chapter_str, title_str, subtitle_str):
    txt_h = comp.AddTool("TextPlus")
    txt_h.StyledText = f"{chapter_str} // {title_str}"
    txt_h.Size = 0.034
    txt_h.Center = [0.32, 0.90]
    txt_h.Red1 = 0.95
    txt_h.Green1 = 0.78
    txt_h.Blue1 = 0.25
    
    txt_s = comp.AddTool("TextPlus")
    txt_s.StyledText = subtitle_str
    txt_s.Size = 0.016
    txt_s.Center = [0.32, 0.86]
    txt_s.Red1 = 0.72
    txt_s.Green1 = 0.84
    txt_s.Blue1 = 0.95
    
    m = comp.AddTool("Merge")
    m.Background.ConnectTo(txt_h.Output)
    m.Foreground.ConnectTo(txt_s.Output)
    return m


# -------------------------------------------------------------
# SCENE 0: IMPERIAL IDENTITY & OVERTURE
# -------------------------------------------------------------
print("Building Scene 0: Imperial Identity...")
comp0 = items[0].GetFusionCompByIndex(1)
mo0 = clean_comp(comp0)
bg0 = create_ambient_background(comp0)

# Hero Logo Card
ldr0 = comp0.AddTool("Loader")
ldr0.Clip = HERO_IMG
xform0 = comp0.AddTool("Transform")
xform0.Input.ConnectTo(ldr0.Output)
xform0.Size = 0.68

shd0 = comp0.AddTool("Shadow")
shd0.Input.ConnectTo(xform0.Output)
shd0.Softness = 0.04
shd0.ShadowOffset = [-0.02, -0.02]

dve0 = comp0.AddTool("DVE")
dve0.Input.ConnectTo(shd0.Output)
dve0.YRotation[0] = -14.0
dve0.YRotation[120] = -7.0
dve0.XRotation[0] = 7.0
dve0.XRotation[120] = 3.0
dve0.Center[0] = [0.58, 0.48]
dve0.Center[120] = [0.54, 0.48]

m_card0 = comp0.AddTool("Merge")
m_card0.Background.ConnectTo(bg0.Output)
m_card0.Foreground.ConnectTo(dve0.Output)

# Floating Royal Crest Badge on Left
ldr_crest0 = comp0.AddTool("Loader")
ldr_crest0.Clip = CREST_IMG
x_crest0 = comp0.AddTool("Transform")
x_crest0.Input.ConnectTo(ldr_crest0.Output)
x_crest0.Size[0] = 0.32
x_crest0.Size[120] = 0.35
x_crest0.Center[0] = [0.22, 0.50]
x_crest0.Center[120] = [0.22, 0.48]

glow_crest0 = comp0.AddTool("SoftGlow")
glow_crest0.Input.ConnectTo(x_crest0.Output)
glow_crest0.Threshold = 0.35
glow_crest0.Gain = 1.3

m_crest0 = comp0.AddTool("Merge")
m_crest0.Background.ConnectTo(m_card0.Output)
m_crest0.Foreground.ConnectTo(glow_crest0.Output)

hdr0 = create_scene_header(comp0, "00", "IMPERIAL IDENTITY", "AFRICAN ROYAL LINEAGE INTELLIGENCE SYSTEM")
b0_1 = create_hud_badge(comp0, "✦ SACRED ROYAL HERITAGE", "Preserving Dynasty Bloodlines Across Eras", [0.80, 0.22])
b0_2 = create_hud_badge(comp0, "✦ ENTERPRISE ARCHIVES", "Multi-Tier Dynasty Council & Verified Pedigree", [0.80, 0.12])

m_h0 = comp0.AddTool("Merge")
m_h0.Background.ConnectTo(m_crest0.Output)
m_h0.Foreground.ConnectTo(hdr0.Output)

m_b1_0 = comp0.AddTool("Merge")
m_b1_0.Background.ConnectTo(m_h0.Output)
m_b1_0.Foreground.ConnectTo(b0_1.Output)

m_b2_0 = comp0.AddTool("Merge")
m_b2_0.Background.ConnectTo(m_b1_0.Output)
m_b2_0.Foreground.ConnectTo(b0_2.Output)

glow0 = comp0.AddTool("Glow")
glow0.Input.ConnectTo(m_b2_0.Output)
glow0.Glow = 0.12
mo0.Input.ConnectTo(glow0.Output)


# -------------------------------------------------------------
# SCENE 1: NEURAL LINEAGE TREE ENGINE (suite_2_tree_canvas.png)
# -------------------------------------------------------------
print("Building Scene 1: Neural Lineage Tree Engine...")
comp1 = items[1].GetFusionCompByIndex(1)
mo1 = clean_comp(comp1)
bg1 = create_ambient_background(comp1)

ldr1 = comp1.AddTool("Loader")
ldr1.Clip = TREE_IMG
xform1 = comp1.AddTool("Transform")
xform1.Input.ConnectTo(ldr1.Output)
xform1.Size = 0.72

shd1 = comp1.AddTool("Shadow")
shd1.Input.ConnectTo(xform1.Output)
shd1.Softness = 0.04
shd1.ShadowOffset = [-0.02, -0.02]

dve1 = comp1.AddTool("DVE")
dve1.Input.ConnectTo(shd1.Output)
dve1.XRotation[0] = 12.0
dve1.XRotation[120] = 7.0
dve1.YRotation[0] = -16.0
dve1.YRotation[120] = -8.0
dve1.Center[0] = [0.48, 0.47]
dve1.Center[120] = [0.45, 0.48]

m_card1 = comp1.AddTool("Merge")
m_card1.Background.ConnectTo(bg1.Output)
m_card1.Foreground.ConnectTo(dve1.Output)

# Reticle targeting patriarch
ret_bg1 = comp1.AddTool("Background")
ret_bg1.TopLeftRed = 0.95
ret_bg1.TopLeftGreen = 0.78
ret_bg1.TopLeftBlue = 0.25
ret_mask1 = comp1.AddTool("EllipseMask")
ret_mask1.Width = 0.055
ret_mask1.Height = 0.055
ret_mask1.BorderWidth = 0.003
ret_mask1.Solid = 0
ret_mask1.Center = [0.55, 0.58]

m_ret1 = comp1.AddTool("Merge")
m_ret1.Background.ConnectTo(m_card1.Output)
m_ret1.Foreground.ConnectTo(ret_bg1.Output)
m_ret1.EffectMask.ConnectTo(ret_mask1.Mask)

hdr1 = create_scene_header(comp1, "01", "NEURAL LINEAGE GRAPH", "INTERACTIVE PEDIGREE CANVAS & MULTI-GENERATION MAP")
b1_1 = create_hud_badge(comp1, "✦ NEURAL HIERARCHY ENGINE", "Dynamic 7-Generation Deep-Zoom Traversal", [0.80, 0.42])
b1_2 = create_hud_badge(comp1, "✦ PEDIGREE COLLAPSE SOLVER", "Sub-Tree Isolation & Polygamous Branches", [0.80, 0.30])

m_h1 = comp1.AddTool("Merge")
m_h1.Background.ConnectTo(m_ret1.Output)
m_h1.Foreground.ConnectTo(hdr1.Output)

m_b1_1 = comp1.AddTool("Merge")
m_b1_1.Background.ConnectTo(m_h1.Output)
m_b1_1.Foreground.ConnectTo(b1_1.Output)

m_b2_1 = comp1.AddTool("Merge")
m_b2_1.Background.ConnectTo(m_b1_1.Output)
m_b2_1.Foreground.ConnectTo(b1_2.Output)

glow1 = comp1.AddTool("Glow")
glow1.Input.ConnectTo(m_b2_1.Output)
glow1.Glow = 0.12
mo1.Input.ConnectTo(glow1.Output)


# -------------------------------------------------------------
# SCENE 2: KINSHIP INTELLIGENCE AI (suite_4_kinship_solver.png)
# -------------------------------------------------------------
print("Building Scene 2: Kinship Intelligence AI...")
comp2 = items[2].GetFusionCompByIndex(1)
mo2 = clean_comp(comp2)
bg2 = create_ambient_background(comp2)

ldr2 = comp2.AddTool("Loader")
ldr2.Clip = KINSHIP_IMG
xform2 = comp2.AddTool("Transform")
xform2.Input.ConnectTo(ldr2.Output)
xform2.Size = 0.72

shd2 = comp2.AddTool("Shadow")
shd2.Input.ConnectTo(xform2.Output)
shd2.Softness = 0.04
shd2.ShadowOffset = [-0.02, -0.02]

dve2 = comp2.AddTool("DVE")
dve2.Input.ConnectTo(shd2.Output)
dve2.XRotation[0] = 9.0
dve2.XRotation[120] = 5.0
dve2.YRotation[0] = 16.0
dve2.YRotation[120] = 8.0
dve2.Center[0] = [0.55, 0.47]
dve2.Center[120] = [0.58, 0.48]

m_card2 = comp2.AddTool("Merge")
m_card2.Background.ConnectTo(bg2.Output)
m_card2.Foreground.ConnectTo(dve2.Output)

# Radar targeting reticle over solver
ret_bg2 = comp2.AddTool("Background")
ret_bg2.TopLeftRed = 0.15
ret_bg2.TopLeftGreen = 0.88
ret_bg2.TopLeftBlue = 0.75
ret_mask2 = comp2.AddTool("EllipseMask")
ret_mask2.Width = 0.075
ret_mask2.Height = 0.075
ret_mask2.BorderWidth = 0.003
ret_mask2.Solid = 0
ret_mask2.Center = [0.58, 0.52]

m_ret2 = comp2.AddTool("Merge")
m_ret2.Background.ConnectTo(m_card2.Output)
m_ret2.Foreground.ConnectTo(ret_bg2.Output)
m_ret2.EffectMask.ConnectTo(ret_mask2.Mask)

hdr2 = create_scene_header(comp2, "02", "KINSHIP MATRIX SOLVER", "GRAPH PATHFINDING & LINEAGE DEGREE COMPUTATION")
b2_1 = create_hud_badge(comp2, "✦ IMPERIAL KINSHIP AI", "Consanguinity Index: 12.5% (2nd Degree)", [0.22, 0.42])
b2_2 = create_hud_badge(comp2, "✦ 4-NODE STEP-PATH RIBBON", "Amina -> Arthur -> Liam -> Aria Kkevo", [0.22, 0.30])

m_h2 = comp2.AddTool("Merge")
m_h2.Background.ConnectTo(m_ret2.Output)
m_h2.Foreground.ConnectTo(hdr2.Output)

m_b1_2 = comp2.AddTool("Merge")
m_b1_2.Background.ConnectTo(m_h2.Output)
m_b1_2.Foreground.ConnectTo(b2_1.Output)

m_b2_2 = comp2.AddTool("Merge")
m_b2_2.Background.ConnectTo(m_b1_2.Output)
m_b2_2.Foreground.ConnectTo(b2_2.Output)

glow2 = comp2.AddTool("Glow")
glow2.Input.ConnectTo(m_b2_2.Output)
glow2.Glow = 0.12
mo2.Input.ConnectTo(glow2.Output)


# -------------------------------------------------------------
# SCENE 3: DYNASTY ANALYTICS & ALLIANCES (suite_5_royal_alliances.png)
# -------------------------------------------------------------
print("Building Scene 3: Dynasty Analytics & Alliances...")
comp3 = items[3].GetFusionCompByIndex(1)
mo3 = clean_comp(comp3)
bg3 = create_ambient_background(comp3)

ldr3 = comp3.AddTool("Loader")
ldr3.Clip = ALLIANCES_IMG
xform3 = comp3.AddTool("Transform")
xform3.Input.ConnectTo(ldr3.Output)
xform3.Size = 0.72

shd3 = comp3.AddTool("Shadow")
shd3.Input.ConnectTo(xform3.Output)
shd3.Softness = 0.04
shd3.ShadowOffset = [-0.02, -0.02]

dve3 = comp3.AddTool("DVE")
dve3.Input.ConnectTo(shd3.Output)
dve3.YRotation[0] = -14.0
dve3.YRotation[120] = -7.0
dve3.XRotation[0] = 6.0
dve3.XRotation[120] = 3.0
dve3.Center[0] = [0.55, 0.48]
dve3.Center[120] = [0.49, 0.48]

m_card3 = comp3.AddTool("Merge")
m_card3.Background.ConnectTo(bg3.Output)
m_card3.Foreground.ConnectTo(dve3.Output)

# HUD Focus frame
foc_bg3 = comp3.AddTool("Background")
foc_bg3.TopLeftRed = 0.95
foc_bg3.TopLeftGreen = 0.78
foc_bg3.TopLeftBlue = 0.25
foc_mask3 = comp3.AddTool("RectangleMask")
foc_mask3.Width = 0.18
foc_mask3.Height = 0.14
foc_mask3.BorderWidth = 0.002
foc_mask3.Solid = 0
foc_mask3.Center = [0.58, 0.45]

m_foc3 = comp3.AddTool("Merge")
m_foc3.Background.ConnectTo(m_card3.Output)
m_foc3.Foreground.ConnectTo(foc_bg3.Output)
m_foc3.EffectMask.ConnectTo(foc_mask3.Mask)

hdr3 = create_scene_header(comp3, "03", "DYNASTY INTELLIGENCE", "ENTERPRISE ANALYTICS & KINGDOM STATISTICS")
b3_1 = create_hud_badge(comp3, "✦ ROYAL ALLIANCE ANALYTICS", "Cross-Kingdom Lineage & Demographic Ties", [0.80, 0.24])
b3_2 = create_hud_badge(comp3, "✦ CHIEFTAINCY COUNCIL TIERS", "Historical Diplomatic Marriages & Treaties", [0.80, 0.13])

m_h3 = comp3.AddTool("Merge")
m_h3.Background.ConnectTo(m_foc3.Output)
m_h3.Foreground.ConnectTo(hdr3.Output)

m_b1_3 = comp3.AddTool("Merge")
m_b1_3.Background.ConnectTo(m_h3.Output)
m_b1_3.Foreground.ConnectTo(b3_1.Output)

m_b2_3 = comp3.AddTool("Merge")
m_b2_3.Background.ConnectTo(m_b1_3.Output)
m_b2_3.Foreground.ConnectTo(b3_2.Output)

glow3 = comp3.AddTool("Glow")
glow3.Input.ConnectTo(m_b2_3.Output)
glow3.Glow = 0.12
mo3.Input.ConnectTo(glow3.Output)


# -------------------------------------------------------------
# SCENE 4: OMNICHANNEL MOBILE FLUTTER (Dual Samsung Galaxy Screens)
# -------------------------------------------------------------
print("Building Scene 4: Omnichannel Mobile Flutter...")
comp4 = items[4].GetFusionCompByIndex(1)
mo4 = clean_comp(comp4)
bg4 = create_ambient_background(comp4)

# Left Phone: Registry View
ldr_reg = comp4.AddTool("Loader")
ldr_reg.Clip = PHONE_REGISTRY
x_reg = comp4.AddTool("Transform")
x_reg.Input.ConnectTo(ldr_reg.Output)
x_reg.Size = 0.44

shd_reg = comp4.AddTool("Shadow")
shd_reg.Input.ConnectTo(x_reg.Output)
shd_reg.Softness = 0.04
shd_reg.ShadowOffset = [-0.02, -0.02]

dve_reg = comp4.AddTool("DVE")
dve_reg.Input.ConnectTo(shd_reg.Output)
dve_reg.YRotation[0] = 14.0
dve_reg.YRotation[120] = 7.0
dve_reg.XRotation = 4.0
dve_reg.Center[0] = [0.38, 0.48]
dve_reg.Center[120] = [0.40, 0.48]

m_reg = comp4.AddTool("Merge")
m_reg.Background.ConnectTo(bg4.Output)
m_reg.Foreground.ConnectTo(dve_reg.Output)

# Right Phone: Tree View
ldr_ptree = comp4.AddTool("Loader")
ldr_ptree.Clip = PHONE_TREE
x_ptree = comp4.AddTool("Transform")
x_ptree.Input.ConnectTo(ldr_ptree.Output)
x_ptree.Size = 0.44

shd_ptree = comp4.AddTool("Shadow")
shd_ptree.Input.ConnectTo(x_ptree.Output)
shd_ptree.Softness = 0.04
shd_ptree.ShadowOffset = [-0.02, -0.02]

dve_ptree = comp4.AddTool("DVE")
dve_ptree.Input.ConnectTo(shd_ptree.Output)
dve_ptree.YRotation[0] = -14.0
dve_ptree.YRotation[120] = -7.0
dve_ptree.XRotation = 4.0
dve_ptree.Center[0] = [0.62, 0.48]
dve_ptree.Center[120] = [0.60, 0.48]

m_ptree = comp4.AddTool("Merge")
m_ptree.Background.ConnectTo(m_reg.Output)
m_ptree.Foreground.ConnectTo(dve_ptree.Output)

hdr4 = create_scene_header(comp4, "04", "OMNICHANNEL MOBILE", "UNIFIED FLUTTER ENGINE FOR SAMSUNG GALAXY & IOS")
b4_1 = create_hud_badge(comp4, "✦ NATIVE FLUTTER ENGINE", "60 FPS Hardware-Accelerated Mobile UX", [0.18, 0.40])
b4_2 = create_hud_badge(comp4, "✦ REAL-TIME OFFLINE CACHE", "Hive Local DB + Bi-Directional Cloud REST API", [0.82, 0.40])

m_h4 = comp4.AddTool("Merge")
m_h4.Background.ConnectTo(m_ptree.Output)
m_h4.Foreground.ConnectTo(hdr4.Output)

m_b1_4 = comp4.AddTool("Merge")
m_b1_4.Background.ConnectTo(m_h4.Output)
m_b1_4.Foreground.ConnectTo(b4_1.Output)

m_b2_4 = comp4.AddTool("Merge")
m_b2_4.Background.ConnectTo(m_b1_4.Output)
m_b2_4.Foreground.ConnectTo(b4_2.Output)

glow4 = comp4.AddTool("Glow")
glow4.Input.ConnectTo(m_b2_4.Output)
glow4.Glow = 0.12
mo4.Input.ConnectTo(glow4.Output)


# -------------------------------------------------------------
# SCENE 5: GRAND FINALE & MONUMENTAL CTA
# -------------------------------------------------------------
print("Building Scene 5: Grand Finale...")
comp5 = items[5].GetFusionCompByIndex(1)
mo5 = clean_comp(comp5)
bg5 = create_ambient_background(comp5)

# Expanding Sacred Geometry Rings
ring_bg5 = comp5.AddTool("Background")
ring_bg5.TopLeftRed = 0.95
ring_bg5.TopLeftGreen = 0.78
ring_bg5.TopLeftBlue = 0.25

ring1 = comp5.AddTool("EllipseMask")
ring1.BorderWidth = 0.003
ring1.Solid = 0
ring1.Width[0] = 0.25
ring1.Width[120] = 0.90
ring1.Height[0] = 0.25
ring1.Height[120] = 0.90

m_ring1 = comp5.AddTool("Merge")
m_ring1.Background.ConnectTo(bg5.Output)
m_ring1.Foreground.ConnectTo(ring_bg5.Output)
m_ring1.EffectMask.ConnectTo(ring1.Mask)
m_ring1.Blend = 0.35

# Royal Crest Centered
ldr_crest5 = comp5.AddTool("Loader")
ldr_crest5.Clip = CREST_IMG
xform_crest5 = comp5.AddTool("Transform")
xform_crest5.Input.ConnectTo(ldr_crest5.Output)
xform_crest5.Size[0] = 0.38
xform_crest5.Size[120] = 0.45
xform_crest5.Center = [0.5, 0.62]

glow_crest5 = comp5.AddTool("SoftGlow")
glow_crest5.Input.ConnectTo(xform_crest5.Output)
glow_crest5.Threshold = 0.35
glow_crest5.Gain = 1.4

m_crest5 = comp5.AddTool("Merge")
m_crest5.Background.ConnectTo(m_ring1.Output)
m_crest5.Foreground.ConnectTo(glow_crest5.Output)

txt_cta1 = comp5.AddTool("TextPlus")
txt_cta1.StyledText = "HONOR YOUR ANCESTORS."
txt_cta1.Size = 0.052
txt_cta1.Center = [0.5, 0.36]
txt_cta1.Red1 = 0.96
txt_cta1.Green1 = 0.82
txt_cta1.Blue1 = 0.28

txt_cta2 = comp5.AddTool("TextPlus")
txt_cta2.StyledText = "UNITE EVERY GENERATION."
txt_cta2.Size = 0.040
txt_cta2.Center = [0.5, 0.29]
txt_cta2.Red1 = 0.88
txt_cta2.Green1 = 0.94
txt_cta2.Blue1 = 1.0

txt_cta3 = comp5.AddTool("TextPlus")
txt_cta3.StyledText = "KKEVO DYNASTY // THE FUTURE OF AFRICAN GENEALOGY"
txt_cta3.Size = 0.022
txt_cta3.Center = [0.5, 0.22]
txt_cta3.Red1 = 0.92
txt_cta3.Green1 = 0.76
txt_cta3.Blue1 = 0.26

txt_cta4 = comp5.AddTool("TextPlus")
txt_cta4.StyledText = "AVAILABLE WORLDWIDE // WEB & MOBILE"
txt_cta4.Size = 0.016
txt_cta4.Center = [0.5, 0.16]
txt_cta4.Red1 = 0.65
txt_cta4.Green1 = 0.80
txt_cta4.Blue1 = 0.95

m_c1 = comp5.AddTool("Merge")
m_c1.Background.ConnectTo(m_crest5.Output)
m_c1.Foreground.ConnectTo(txt_cta1.Output)

m_c2 = comp5.AddTool("Merge")
m_c2.Background.ConnectTo(m_c1.Output)
m_c2.Foreground.ConnectTo(txt_cta2.Output)

m_c3 = comp5.AddTool("Merge")
m_c3.Background.ConnectTo(m_c2.Output)
m_c3.Foreground.ConnectTo(txt_cta3.Output)

m_c4 = comp5.AddTool("Merge")
m_c4.Background.ConnectTo(m_c3.Output)
m_c4.Foreground.ConnectTo(txt_cta4.Output)

glow5 = comp5.AddTool("Glow")
glow5.Input.ConnectTo(m_c4.Output)
glow5.Glow = 0.16
mo5.Input.ConnectTo(glow5.Output)


# -------------------------------------------------------------
# EDIT PAGE FLOW: TRANSITIONS, MARKERS & SOUNDTRACK
# -------------------------------------------------------------
print("Configuring Edit Page flow...")

# Transitions
for i in range(len(items) - 1):
    try:
        items[i].AddTransition({
            "type": "Cross Dissolve",
            "category": "simple",
            "position": "end",
            "alignment": "center",
            "duration": 14
        })
    except Exception:
        pass

# Color-code timeline clips
clip_colors = ["Orange", "Yellow", "Green", "Teal", "Blue", "Purple"]
for i, item in enumerate(items):
    try:
        item.SetClipColor(clip_colors[i % len(clip_colors)])
    except Exception:
        pass

# Markers
markers = [
    (86400, "Cyan", "00 // IMPERIAL BRAND", "Overture & Architecture Reveal"),
    (86520, "Yellow", "01 // NEURAL LINEAGE GRAPH", "Interactive Tree Canvas & Conduits"),
    (86640, "Green", "02 // KINSHIP MATRIX SOLVER", "AI Relationship & Radar Scanner"),
    (86760, "Blue", "03 // DYNASTY INTELLIGENCE", "Kingdom Demographics & Alliances"),
    (86880, "Pink", "04 // OMNICHANNEL MOBILE", "Samsung Galaxy Flutter Showcase"),
    (87000, "Red", "05 // GRAND FINALE", "Imperial Seal & Monumental CTA")
]

for frame, color, name, note in markers:
    try:
        timeline.AddMarker(frame, color, name, note, 120)
    except Exception:
        pass

# Render cache smart
project.SetSetting("colorRenderCacheMode", "Smart")

# Park playhead
timeline.SetCurrentTimecode("01:00:00:00")

print("\nREEL SCRIPT FINISHED CLEANLY!")
