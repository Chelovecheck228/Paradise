/**
 * Creates a TGUI input list window and returns the user's response.
 *
 * This proc should be used to create alerts that the caller will wait for a response from.
 * Arguments:
 * * user - The user to show the input box to.
 * * message - The content of the input box, shown in the body of the TGUI window.
 * * title - The title of the input box, shown on the top of the TGUI window.
 * * items - The options that can be chosen by the user, each string is assigned a button on the UI.
 * * default - If an option is already preselected on the UI. Current values, etc.
 * * timeout - The timeout of the input box, after which the menu will close and qdel itself. Set to zero for no timeout.
 */
/proc/tgui_input_list(mob/user, message, title = "Select", list/items, default, timeout = 0, ui_state = GLOB.always_state)
	if(!user)
		user = usr
	if(!length(items))
		return null
	if(!istype(user))
		if(!isclient(user))
			return
		var/client/client = user
		user = client.mob

	/// Client does NOT have tgui_input on: Returns regular input
	if(user.client?.prefs?.toggles2 & PREFTOGGLE_2_DISABLE_TGUI_LISTS)
		return input(user, message, title, default) as null|anything in items

	var/datum/tgui_list_input/input = new(user, message, title, items, default, timeout, ui_state)
	input.ui_interact(user)
	input.wait()
	if(input)
		. = input.choice
		qdel(input)

/**
 * # tgui_list_input
 *
 * Datum used for instantiating and using a TGUI-controlled list input that prompts the user with
 * a message and shows a list of selectable options
 */
/datum/tgui_list_input
	/// The title of the TGUI window
	var/title
	/// The textual body of the TGUI window
	var/message
	/// The list of items (responses) provided on the TGUI window
	var/list/items
	/// Buttons (strings specifically) mapped to the actual value (e.g. a mob or a verb)
	var/list/items_map
	/// The button that the user has pressed, null if no selection has been made
	var/choice
	/// The default button to be selected
	var/default
	/// The time at which the tgui_list_input was created, for displaying timeout progress.
	var/start_time
	/// The lifespan of the tgui_list_input, after which the window will close and delete itself.
	var/timeout
	/// Boolean field describing if the tgui_list_input was closed by the user.
	var/closed
	/// The TGUI UI state that will be returned in ui_state(). Default: always_state
	var/datum/ui_state/state

/datum/tgui_list_input/New(mob/user, message, title, list/items, default, timeout, ui_state)
	src.title = title
	src.message = message
	src.items = list()
	src.items_map = list()
	src.default = default
	src.state = ui_state
	// Gets rid of illegal characters
	var/static/regex/whitelistedWords = regex(@{"([^\u0020-\u8000]+)"})
	for(var/i in items)
		if(!i)
			continue
		var/string_key = whitelistedWords.Replace("[i]", "")
		src.items += string_key
		src.items_map[string_key] = i

	if(timeout)
		src.timeout = timeout
		start_time = world.time
		QDEL_IN(src, timeout)

/datum/tgui_list_input/Destroy(force)
	SStgui.close_uis(src)
	state = null
	QDEL_NULL(items)
	return ..()

/**
 * Waits for a user's response to the tgui_list_input's prompt before returning. Returns early if
 * the window was closed by the user.
 */
/datum/tgui_list_input/proc/wait()
	while(!choice && !closed)
		stoplag(1)

/datum/tgui_list_input/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.always_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "ListInput", title, 325, 355, master_ui, state)
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/tgui_list_input/ui_close(mob/user)
	. = ..()
	closed = TRUE

/datum/tgui_list_input/ui_static_data(mob/user)
	var/list/data = list()
	data["init_value"] = default || items[1]
	data["items"] = uniquelist(items)
	data["message"] = message
	data["title"] = title
	return data

/datum/tgui_list_input/ui_data(mob/user)
	var/list/data = list()
	if(timeout)
		data["timeout"] = clamp((timeout - (world.time - start_time) - 1 SECONDS) / (timeout - 1 SECONDS), 0, 1)
	return data

/datum/tgui_list_input/ui_act(action, list/params)
	. = ..()
	if (.)
		return
	switch(action)
		if("choose")
			if (!(params["choice"] in items))
				return
			src.choice = items_map[params["choice"]]
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE
		if("cancel")
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE
