//Xenobio control console
/mob/camera/aiEye/remote/xenobio
	visible_icon = 1
	icon = 'icons/obj/abductor.dmi'
	icon_state = "camera_target"
	var/allowed_area = null

/mob/camera/aiEye/remote/xenobio/New(loc)
	var/area/A = get_area(loc)
	allowed_area = A.name
	..()

/mob/camera/aiEye/remote/xenobio/setLoc(var/t)
	var/area/new_area = get_area(t)
	if(new_area && new_area.name == allowed_area || istype(new_area, /area/toxins/xenobiology ))
		return ..()
	else
		return

/obj/machinery/computer/camera_advanced/xenobio
	name = "Slime management console"
	desc = "A computer used for remotely handling slimes."
	networks = list("SS13")
	circuit = /obj/item/weapon/circuitboard/computer/xenobiology
	off_action = new/datum/action/innate/camera_off/xenobio
	var/datum/action/innate/slime_place/slime_place_action = new
	var/datum/action/innate/slime_pick_up/slime_up_action = new
	var/datum/action/innate/feed_slime/feed_slime_action = new
	var/datum/action/innate/monkey_recycle/monkey_recycle_action = new

	var/list/stored_slimes = list()
	var/max_slimes = 5
	var/monkeys = 0

	icon_screen = "slime_comp"
	icon_keyboard = "rd_key"

	light_color = LIGHT_COLOR_PINK

/obj/machinery/computer/camera_advanced/xenobio/CreateEye()
	eyeobj = new /mob/camera/aiEye/remote/xenobio(get_turf(src))
	eyeobj.origin = src
	eyeobj.visible_icon = 1
	eyeobj.icon = 'icons/obj/abductor.dmi'
	eyeobj.icon_state = "camera_target"

/obj/machinery/computer/camera_advanced/xenobio/GrantActions(mob/living/user)
	off_action.target = user
	off_action.Grant(user)

	jump_action.target = user
	jump_action.Grant(user)

	slime_up_action.target = src
	slime_up_action.Grant(user)

	slime_place_action.target = src
	slime_place_action.Grant(user)

	feed_slime_action.target = src
	feed_slime_action.Grant(user)

	monkey_recycle_action.target = src
	monkey_recycle_action.Grant(user)

/obj/machinery/computer/camera_advanced/xenobio/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/weapon/reagent_containers/food/snacks/monkeycube))
		monkeys++
		to_chat(user, "<span class='notice'>You feed [O] to [src]. It now has [monkeys] monkey cubes stored.</span>")
		user.drop_item()
		qdel(O)
		return
	else if(istype(O, /obj/item/weapon/storage/bag))
		var/obj/item/weapon/storage/P = O
		var/loaded = 0
		for(var/obj/G in P.contents)
			if(istype(G, /obj/item/weapon/reagent_containers/food/snacks/monkeycube))
				loaded = 1
				monkeys++
				qdel(G)
		if (loaded)
			to_chat(user, "<span class='notice'>You fill [src] with the monkey cubes stored in [O]. [src] now has [monkeys] monkey cubes stored.</span>")
		return
	..()

/datum/action/innate/camera_off/xenobio/Activate()
	if(!target || !isliving(target))
		return
	var/mob/living/C = target
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/origin = remote_eye.origin
	origin.current_user = null
	origin.jump_action.Remove(C)
	origin.slime_place_action.Remove(C)
	origin.slime_up_action.Remove(C)
	origin.feed_slime_action.Remove(C)
	origin.monkey_recycle_action.Remove(C)
	//All of this stuff below could probably be a proc for all advanced cameras, only the action removal needs to be camera specific
	remote_eye.eye_user = null
	C.reset_perspective(null)
	if(C.client)
		C.client.images -= remote_eye.user_image
		for(var/datum/camerachunk/chunk in remote_eye.visibleCameraChunks)
			C.client.images -= chunk.obscured
	C.remote_control = null
	C.unset_machine()
	src.Remove(C)


/datum/action/innate/slime_place
	name = "Place Slimes"
	button_icon_state = "slime_down"

/datum/action/innate/slime_place/Activate()
	if(!target || !isliving(owner))
		return
	var/mob/living/C = owner
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/X = target

	if(cameranet.checkTurfVis(remote_eye.loc))
		for(var/mob/living/simple_animal/slime/S in X.stored_slimes)
			S.loc = remote_eye.loc
			S.visible_message("[S] warps in!")
			X.stored_slimes -= S
	else
		to_chat(owner, "<span class='notice'>Target is not near a camera. Cannot proceed.</span>")

/datum/action/innate/slime_pick_up
	name = "Pick up Slime"
	button_icon_state = "slime_up"

/datum/action/innate/slime_pick_up/Activate()
	if(!target || !isliving(owner))
		return
	var/mob/living/C = owner
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/X = target

	if(cameranet.checkTurfVis(remote_eye.loc))
		for(var/mob/living/simple_animal/slime/S in remote_eye.loc)
			if(X.stored_slimes.len >= X.max_slimes)
				break
			if(!S.ckey)
				if(S.buckled)
					S.Feedstop(silent=1)
				S.visible_message("[S] vanishes in a flash of light!")
				S.loc = X
				X.stored_slimes += S
	else
		to_chat(owner, "<span class='notice'>Target is not near a camera. Cannot proceed.</span>")


/datum/action/innate/feed_slime
	name = "Feed Slimes"
	button_icon_state = "monkey_down"

/datum/action/innate/feed_slime/Activate()
	if(!target || !isliving(owner))
		return
	var/mob/living/C = owner
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/X = target

	if(cameranet.checkTurfVis(remote_eye.loc))
		if(X.monkeys >= 1)
			var/mob/living/carbon/monkey/food = new /mob/living/carbon/monkey(remote_eye.loc)
			food.LAssailant = C
			X.monkeys --
			to_chat(owner, "[X] now has [X.monkeys] monkeys left.")
	else
		to_chat(owner, "<span class='notice'>Target is not near a camera. Cannot proceed.</span>")


/datum/action/innate/monkey_recycle
	name = "Recycle Monkeys"
	button_icon_state = "monkey_up"

/datum/action/innate/monkey_recycle/Activate()
	if(!target || !isliving(owner))
		return
	var/mob/living/C = owner
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/X = target

	if(cameranet.checkTurfVis(remote_eye.loc))
		for(var/mob/living/carbon/monkey/M in remote_eye.loc)
			if(M.stat)
				M.visible_message("[M] vanishes as they are reclaimed for recycling!")
				X.monkeys = round(X.monkeys + 0.2,0.1)
				qdel(M)
	else
		to_chat(owner, "<span class='notice'>Target is not near a camera. Cannot proceed.</span>")
