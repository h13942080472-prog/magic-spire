extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Assist=preload("res://core/hand_assist.gd")

static func run(t) -> void:
 for pose in ["stand","sit","lie"]:
  var g=Game.new(42);g.state.posture=pose;g.state.wall_distance=1
  for point in ["eyes","mouth","neck","shoulder","upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist","palm_left","fingers_right","thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle","foot","toes"]+g.SpecialEquipment.slots():
   t.check(Assist.at_point(g,point).size()==2,"ASSIST free arms touch every precise position "+pose+point)
  g._install_template("belt","upper_arm",4,10,false,"fixture",1,0,0,"upper_arm_top")
  var elbow=g._install_template("belt","upper_arm",4,10,false,"fixture",1,0,0,"above_elbow")
  t.check(Assist.preview(g,elbow).bonus==2 and not "upper_arm_top" in Assist.profile(g,"left").points,"ASSIST exception reaches above elbow only "+pose)
  for point in g.SpecialEquipment.slots():
   t.check(Assist.at_point(g,point).size()==2,"ASSIST all six placeholders reachable with free wrist and no forearm torso fixation "+pose+point)
  t.check(Assist.at_point(g,"below_knee").is_empty(),"ASSIST limited arms do not invent whole lower-leg reach "+pose)
  t.check(Assist.at_point(g,"thigh_root").size()==2 and Assist.at_point(g,"special_3_a").size()==2 and Assist.at_point(g,"special_3_b").size()==2,"ASSIST ordinary thigh reach also includes region3 "+pose)
  var fixture=g._install_template("belt","forearm",10,10,false,"fixture",1,-1,0,"mid_forearm")
  t.check(not fixture.is_empty() and Assist.at_point(g,"above_elbow").size()==2 and Assist.at_point(g,"special_1_a").size()==2 and Assist.at_point(g,"special_2_a").size()==2,"ASSIST torso binding preserves unrelated extra reach "+pose)
  t.check(Assist.at_point(g,"thigh_root").is_empty() and Assist.at_point(g,"special_3_a").is_empty(),"ASSIST back forearm fixation retains contact restriction "+pose)
  g.add_fixture("wrist",4)
  t.check(Assist.SIDES.all(func(side):return Assist.profile(g,side).points.is_empty()),"ASSIST wrist block disables both hands "+pose)
 var g=Game.new(42);g.state.wall_distance=1
 var target=g.add_fixture("ankle",4)
 for mode in ["strain","slip","magic_slip"]:
  t.check(g.escape_preview(target,mode,5).damage==7,"ASSIST two hands add two before multipliers "+mode)
 target.locked=true
 t.check(g.escape_preview(target,"strain",5).damage==3.5 and g.escape_preview(target,"slip",5).damage==7,"ASSIST lock halves strain including assist but not slip")
 target.durability=10
 t.check(g.escape_preview(target,"slip",5).damage==0 and g.escape_preview(target,"magic_slip",5).damage==3.5,"ASSIST does not bypass normal tier3 immunity")
 target.durability=4;target.locked=false
 var root=g._install_assembly("wrap","left","fixture",1,1)
 t.check(not root.is_empty() and Assist.preview(g,target).hands==["right"] and g.escape_preview(target,"strain",5).damage==6,"ASSIST independent left wrap leaves only right-hand bonus")
 var wrap=root.components[0]
 t.check(Assist.preview(g,wrap).hands==["right"],"ASSIST other hand can assist exposed wrap, wrapped hand cannot assist itself")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"ASSIST preview never mutates state or RNG")
 var card=t.hand_card(g,"strain");var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 t.check(g.candidate_detail(c).contains("右手辅助＋1") and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"ASSIST candidate explains side and rejects stale version atomically")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._equipment(target.id).is_empty() and g.state.energy==before.energy-1,"ASSIST actual card applies damage once without extra energy")
 t.check(g.state.logs.any(func(e):return e.data.has("assist") and e.data.assist.hands==["right"] and e.text.contains("手部辅助")),"ASSIST mechanical log preserves actual helper and formula")
 g=Game.new(42);g.state.wall_distance=1
 var inner=g.add_fixture("thigh",8,10,false,0);g._install_template("belt","thigh",4,10,false,"fixture",1,1,0,inner.points[0])
 t.check(Assist.preview(g,inner).bonus==0 and g.escape_preview(inner,"slip",5).reason!="","ASSIST outer cover prevents touching inner target")
 g=Game.new(42);g.state.wall_distance=1
 g.add_fixture("upper_arm",4)
 var ordinary=g.add_fixture("forearm",4)
 t.check(not ordinary.is_empty() and Assist.at_point(g,"above_elbow").size()==2,"ASSIST ordinary forearm restraint is not torso fixation")
 # The next candidate re-evaluates hand availability after wrist removal.
 g=Game.new(42);g.state.wall_distance=1
 var wrist=g.add_fixture("wrist",4);target=g.add_fixture("ankle",8)
 g._gain_card("chain");card=t.hand_card(g,"chain")
 t.check(t.action(g,"card",{"uid":card.uid,"target":wrist.id}).ok and g._equipment(wrist.id).is_empty(),"ASSIST first chain hit releases wrists with no helper")
 var next_card=t.hand_card(g,"strain")
 var second=t.find_action(g,"card",{"uid":next_card.uid,"target":target.id})
 t.check(second.valid and second.payload.preview.assist.bonus==2 and second.cost==1,"ASSIST next card gains freed hands without additional assist cost")
 # Target-specific conditions never change placeholder capacity or install eligibility.
 t.check(g._installation_reason("belt","special_3_a",1)!="" and g.SpecialEquipment.slots().size()==7,"ASSIST reach does not authorize ordinary placeholder equipment")

 g=Game.new(42);g.state.wall_distance=1;g.state.posture="sit"
 g.add_fixture("fingers",4);target=g.add_fixture("ankle",4)
 t.check(Assist.preview(g,target).bonus==0,"ASSIST fingers must be free even when palms are usable")
 var a=g._install_template("rope","thigh",8,10,false,"fixture",1,-1,0,"above_knee");var b=g.add_fixture("calf",8)
 var link=g._install_link(a.id,b.id,8,"fixture",1,[])
 t.check(not link.is_empty() and Assist.preview(g,link).bonus==0,"ASSIST blocked fingers cannot assist links either")

 # Shared contact reasons are target-specific and do not grant tool capabilities.
 g=Game.new(42);g.state.posture="sit";g.state.wall_distance=0
 var blocked=g.add_fixture("wrist",4);target=g.add_fixture("ankle",8)
 var result=Assist.preview(g,target)
 t.check(result.bonus==0 and result.reasons.size()==2 and result.reasons.all(func(x):return x.code=="wrist_blocked") and result.detail.contains("手腕受限"),"CONTACT no assist explains both blocked wrists")
 card=t.hand_card(g,"strain")
 t.check(g.candidate_detail(t.find_action(g,"card",{"uid":card.uid,"target":target.id})).contains("手腕受限"),"CONTACT target choice carries the actual no-assist reason")
 g.state.equipment.erase(blocked);g.add_fixture("fingers",4);g._gain_tool("shard")
 var tool=g.state.items.back()
 t.check(Assist.preview(g,target).bonus==0 and not t.find_action(g,"manual",{"target":target.id}).valid and not t.find_action(g,"item_use",{"target":target.id,"item":tool.id}).valid,"CONTACT blocked fingers disable assistance and fine operations")
 tool.mount="foot_wall"
 t.check(g.InstalledTools.reason(g,tool,target)=="","CONTACT mounted tool can contact target without free hands")
 g=Game.new(42);g.state.posture="sit"
 inner=g._install_template("belt","thigh",8,10,false,"fixture",1,0,0,"mid_thigh")
 var cover=g._install_template("belt","thigh",4,10,false,"fixture",1,1,0,"mid_thigh")
 result=Assist.preview(g,inner)
 t.check(result.bonus==0 and result.reasons.all(func(x):return x.code=="covered") and g.Tools.Contact.reason(g,inner,"manual").contains("外层"),"CONTACT shared outer cover reason for assist and manual")
 g.state.equipment.erase(cover)
 g._install_template("belt","thigh",4,10,false,"fixture",1,1,0,"above_knee")
 t.check(Assist.preview(g,inner).bonus==2 and t.find_action(g,"manual",{"target":inner.id}).valid,"CONTACT another exact segment does not hide this target")
 g=Game.new(42);g.add_fixture("upper_arm",4);target=g.add_fixture("calf",4)
 result=Assist.preview(g,target)
 t.check(result.bonus==0 and result.reasons.all(func(x):return x.code=="out_of_reach"),"CONTACT out-of-reach differs from outer cover")
 g=Game.new(42);target=g.add_fixture("fingers",4)
 result=Assist.preview(g,target)
 t.check(result.reasons.all(func(x):return x.code=="fingers_blocked"),"CONTACT own fingers cannot provide self-assistance")

 # Palms scale the contribution after finger qualification, not the whole damage.
 g=Game.new(42);g.state.posture="sit";g.state.wall_distance=1
 var palms=g.add_fixture("palm",4)
 target=g.add_fixture("ankle",4)
 result=Assist.preview(g,target)
 t.check(result.bonus==1.0 and result.hands.size()==2 and result.contributions.all(func(c):return c.bonus==0.5),"ASSIST two unavailable palms contribute half each")
 for mode in ["strain","slip","magic_slip"]:
  t.check(g.escape_preview(target,mode,5).damage==6.0,"ASSIST half palms affect only base assistance "+mode)
 target.locked=true
 t.check(g.escape_preview(target,"strain",5).damage==3.0,"ASSIST half palm bonus enters existing lock multiplier")
 target.locked=false
 # A side wrap is installed before a legal outer palm restraint.
 g.state.equipment.erase(palms)
 g._install_assembly("wrap","right","fixture",1,1)
 palms=g._install_template("fine_belt","palm",4,10,false,"fixture")
 result=Assist.preview(g,target)
 t.check(result.hands==["left"] and result.bonus==0.5 and result.label=="左手辅助＋0.5" and result.detail.contains("手掌不能使用"),"ASSIST one finger-free hand keeps fractional label")
 t.check(result.reasons.any(func(r):return r.side=="right" and r.code=="fingers_blocked"),"ASSIST finger condition wins over palm condition")
 g._gain_tool("shard")
 t.check(not t.find_action(g,"item_use",{"item":g.state.items.back().id,"target":target.id}).valid,"ASSIST half assistance does not enable handheld cutting")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"ASSIST fractional preview remains read-only")
 card=t.hand_card(g,"strain");c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 t.check(g.candidate_detail(c).contains("＋0.5") and c.payload.preview.assist.bonus==0.5,"ASSIST candidate exposes exact half contribution")
 var energy=g.state.energy
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==energy-1 and g.state.logs.any(func(e):return e.data.has("assist") and e.data.assist.bonus==0.5),"ASSIST real action pays once and logs half contribution")
