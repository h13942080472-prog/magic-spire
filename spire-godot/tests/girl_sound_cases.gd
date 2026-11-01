extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Receipt=preload("res://core/resource_feedback.gd")
const Profile=preload("res://data/girl_sound_profile.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 receipt_priority(t)
 committed(t)

static func receipt_priority(t) -> void:
 var g=Game.new(42);var receipt=Receipt.new();g._resource_feedback=receipt
 receipt.capture(g.state)
 g.Pressure.gain(g,5,"音频测试")
 receipt.voice(false,false,0)
 t.check(receipt.sounds.has(Profile.cue("edge",false)),"VOICE positive pleasure gain emits one clear edge cue")
 receipt.sounds.clear();receipt.installed=true;receipt.damaged=true;receipt.pleasure_gained=true
 receipt.voice(true,true,1)
 t.check(receipt.sounds.keys()==[Profile.cue("orgasm",true)],"VOICE simultaneous triggers collapse to gagged orgasm priority")
 receipt.sounds.clear();receipt.voice(true,false,0)
 t.check(receipt.sounds.keys()==[Profile.cue("struggle",false)],"VOICE successful card equipment damage outranks installation and pleasure")
 receipt.sounds.clear();receipt.damaged=false;receipt.voice(false,true,0)
 t.check(receipt.sounds.keys()==[Profile.cue("hit",true)],"VOICE installation outranks pleasure and uses final gag state")

static func committed(t) -> void:
 var g=Game.new(42);g.state.pressure=10
 var result=Cards.play(t,g,"self_satisfaction",true)
 t.check(result.ok and result.get("sound_feedback",[]).has(Profile.cue("edge",false)),"VOICE committed pleasure card emits clear edge")
 g=Game.new(42);g._install_template("mouth_band","mouth",4,10,false,"fixture")
 g.state.pressure=10;result=Cards.play(t,g,"self_satisfaction",true)
 t.check(result.ok and result.get("sound_feedback",[]).has(Profile.cue("edge",true)),"VOICE a surviving mouth restraint selects gagged edge")
 g=Game.new(42,true,"climax_card")
 var card=g.state.hand.filter(func(row):return row.type=="strain")[-1]
 var choice=t.find_action(g,"card",{"uid":card.uid,"free":true})
 result=g.dispatch(g.command(choice.payload,g.state.version),g.state.version)
 t.check(result.ok and result.get("sound_feedback",[]).has(Profile.cue("orgasm",false)),"VOICE formal climax emits orgasm instead of its pressure or equipment side effects")
 g=Game.new(42)
 var target=g.add_fixture("ankle",8);card=Cards.give(g,"strain")
 choice=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false},true)
 result=g.dispatch(g.command(choice.payload,g.state.version),g.state.version)
 t.check(result.ok and result.get("sound_feedback",[]).has(Profile.cue("struggle",false)),"VOICE successful card damage emits struggle")
 g=Game.new(42);g._discard_end();g.state.energy=20
 target=g.add_fixture("ankle",10)
 t.check(Cards.play(t,g,"letter_opener",false).ok,"VOICE passive damage negative setup activates the bound opener")
 for i in range(2): t.check(Cards.play(t,g,"pleasure_conversion",true).ok,"VOICE passive damage negative setup advances the opener")
 var passive_target=target.id;var before=g._equipment(passive_target).durability
 result=Cards.play(t,g,"pleasure_conversion",true)
 t.check(result.ok and g._equipment(passive_target).durability<before and not result.get("sound_feedback",[]).has(Profile.cue("struggle",false)),"VOICE card-time passive power damage does not masquerade as direct card struggle")
 g=Game.new(42);result=t.action(g,"end")
 var voice=result.get("sound_feedback",[]).filter(func(cue):return str(cue).begins_with("voice_hit"))
 t.check(result.ok and voice.size()==1,"VOICE one enemy submission with multiple installations emits one hit cue")
 var receipt=Receipt.new();g._resource_feedback=receipt
 target=g.add_fixture("ankle",8);receipt.sounds.clear();receipt.installed=false
 g._apply_equipment_damage(target,1,"strain",true)
 receipt.voice(false,false,0)
 t.check(not receipt.sounds.keys().any(func(cue):return str(cue).begins_with("voice_")),"VOICE non-card equipment damage does not masquerade as struggle")
