
#define NEWSPAPER_COVER 1
#define NEWSPAPER_MIDDLE 2
#define NEWSPAPER_END 3

/obj/item/weapon/newspaper
	name = "newspaper"
	desc = "An issue of The Griffon, the newspaper circulating aboard Nanotrasen Space Stations."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "newspaper"
	w_class = WEIGHT_CLASS_SMALL
	attack_verb = list("bapped")
	var/screen = 0
	var/pages = 0
	var/curr_page = 0
	var/list/datum/newscaster/feed_channel/news_content = list()
	var/scribble=""
	var/scribble_page
	var/wantedAuthor
	var/wantedCriminal
	var/wantedBody
	var/wantedPhoto
	var/creationTime

/obj/item/weapon/newspaper/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is focusing intently on [src]! It looks like [user.p_theyre()] trying to commit sudoku... until [user.p_their()] eyes light up with realization!</span>",
	"<span class='boldwarning'>You focus intently on [src], trying to commit sodoku... Until your eyes light up in realization!</span>")
	user.say("JOURNALISM IS MY CALLING! EVERYBODY APPRECIATES UNBIASED REPORTI-GLORF")
	var/mob/living/carbon/human/H = user
	var/obj/item/weapon/reagent_containers/food/drinks/bottle/whiskey/W = new(get_turf(H))
	playsound(H, 'sound/items/drink.ogg', rand(10,50), 1)
	W.reagents.trans_to(H, W.reagents.total_volume)
	user.visible_message("<span class='suicide'>[user] downs the contents of [W.name] in one gulp! Shoulda stuck to sudoku!</span>",
	"<span class='boldwarning'>You down the contents of [W] in one gulp! Shoulda stuck to sodoku!</span>")

	return(TOXLOSS)

/obj/item/weapon/newspaper/attack_self(mob/user)
	view(user)

/obj/item/weapon/newspaper/view(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		var/list/dat = list()
		pages = 0
		switch(screen)
			if(NEWSPAPER_COVER) //Cover
				dat+="<DIV ALIGN='center'><B><FONT SIZE=6>The Griffon</FONT></B></div>"
				dat+="<DIV ALIGN='center'><FONT SIZE=2>Nanotrasen-standard newspaper, for use on Nanotrasen? Space Facilities</FONT></div><HR>"
				if(isemptylist(news_content))
					if(wantedAuthor)
						dat+="Contents:<ul><B><FONT COLOR='red'>**</FONT>Important Security Announcement<FONT COLOR='red'>**</FONT></B> <FONT SIZE=2>\[page [pages+2]\]</FONT></ul>"
					else
						dat+="<I>Other than the title, the rest of the newspaper is unprinted...</I>"
				else
					dat+="Contents:<ul>"
					for(var/datum/newscaster/feed_channel/NP in news_content)
						pages++
					if(wantedAuthor)
						dat+="<B><FONT COLOR='red'>**</FONT>Important Security Announcement<FONT COLOR='red'>**</FONT></B> <FONT SIZE=2>\[page [pages+2]\]</FONT>"
					var/temp_page=0
					for(var/datum/newscaster/feed_channel/NP in news_content)
						temp_page++
						dat+="<B>[NP.channel_name]</B> <FONT SIZE=2>\[page [temp_page+1]\]</FONT>"
					dat+="</ul>"
				if(scribble_page==curr_page)
					dat+="<I>There is a small scribble near the end of this page... It reads: \"[scribble]\"</I>"
				dat+= "<HR><DIV STYLE='float:right;'><A href='?src=\ref[src];next_page=1'>Next Page</A></DIV> <div style='float:left;'><A href='?src=\ref[human_user];mach_close=newspaper_main'>Done reading</A></DIV>"
			if(NEWSPAPER_MIDDLE) // X channel pages inbetween.
				for(var/datum/newscaster/feed_channel/NP in news_content)
					pages++
				var/datum/newscaster/feed_channel/C = news_content[curr_page]
				dat += "<FONT SIZE=4><B>[C.channel_name]</B></FONT><FONT SIZE=1> \[created by: <FONT COLOR='maroon'>[C.returnAuthor(notContent(C.authorCensorTime))]</FONT>\]</FONT>"
				if(notContent(C.DclassCensorTime))
					dat+="This channel was deemed dangerous to the general welfare of the station and therefore marked with a <B><FONT COLOR='red'>D-Notice</B></FONT>. Its contents were not transferred to the newspaper at the time of printing."
				else
					if(isemptylist(C.messages))
						dat+="No Feed stories stem from this channel..."
					else
						var/i = 0
						for(var/datum/newscaster/feed_message/MESSAGE in C.messages)
							if(MESSAGE.creationTime > creationTime)
								if(i == 0)
									dat+="No Feed stories stem from this channel..."
								break
							if(i == 0)
								dat+="<ul>"
							i++
							dat+="-[MESSAGE.returnBody(notContent(MESSAGE.bodyCensorTime))] "
							if(MESSAGE.img)
								user << browse_rsc(MESSAGE.img, "tmp_photo[i].png")
								dat+="<img src='tmp_photo[i].png' width = '180'>"
							dat+="<FONT SIZE=1>\[Story by <FONT COLOR='maroon'>[MESSAGE.returnAuthor(notContent(MESSAGE.authorCensorTime))]</FONT>\]</FONT>"
						dat+="</ul>"
				if(scribble_page==curr_page)
					dat+="<I>There is a small scribble near the end of this page... It reads: \"[scribble]\"</I>"
				dat+= "<HR><DIV STYLE='float:left;'><A href='?src=\ref[src];prev_page=1'>Previous Page</A></DIV> <DIV STYLE='float:right;'><A href='?src=\ref[src];next_page=1'>Next Page</A></DIV>"
			if(NEWSPAPER_END) //Last page
				for(var/datum/newscaster/feed_channel/NP in news_content)
					pages++
				if(wantedAuthor!=null)
					dat+="<DIV STYLE='float:center;'><FONT SIZE=4><B>Wanted Issue:</B></FONT SIZE></DIV>"
					dat+="<B>Criminal name</B>: <FONT COLOR='maroon'>[wantedCriminal]</FONT>"
					dat+="<B>Description</B>: [wantedBody]"
					dat+="<B>Photo:</B>: "
					if(wantedPhoto)
						user << browse_rsc(wantedPhoto, "tmp_photow.png")
						dat+="<img src='tmp_photow.png' width = '180'>"
					else
						dat+="None"
				else
					dat+="<I>Apart from some uninteresting classified ads, there's nothing on this page...</I>"
				if(scribble_page==curr_page)
					dat+="<I>There is a small scribble near the end of this page... It reads: \"[scribble]\"</I>"
				dat+= "<HR><DIV STYLE='float:left;'><A href='?src=\ref[src];prev_page=1'>Previous Page</A></DIV>"
		dat+="<HR><div align='center'>[curr_page+1]</div>"
		human_user << browse(dat.Join("<br>"), "window=newspaper_main;size=300x400")
		onclose(human_user, "newspaper_main")
	else
		to_chat(user, "The paper is full of unintelligible symbols!")

/obj/item/weapon/newspaper/proc/notContent(list/L)
	if(!L.len)
		return FALSE
	for(var/i=L.len;i>0;i--)
		var/num = abs(L[i])
		if(creationTime <= num)
			continue
		else
			if(L[i] > 0)
				return TRUE
			else
				return FALSE
	return FALSE

/obj/item/weapon/newspaper/Topic(href, href_list)
	var/mob/living/U = usr
	..()
	if((src in U.contents) || (isturf(loc) && in_range(src, U)))
		if(href_list["next_page"])
			if(curr_page == pages+1)
				return //Don't need that at all, but anyway.
			if(curr_page == pages) //We're at the middle, get to the end
				screen = NEWSPAPER_END
			else
				if(curr_page == 0) //We're at the start, get to the middle
					screen = NEWSPAPER_MIDDLE
			curr_page++
			playsound(src, "pageturn", 50, 1)
		else if(href_list["prev_page"])
			if(curr_page == 0)
				return
			if(curr_page == 1)
				screen = NEWSPAPER_COVER
			else
				if(curr_page == pages+1) //we're at the end, let's go back to the middle.
					screen = NEWSPAPER_MIDDLE
			curr_page--
			playsound(src, "pageturn", 50, 1)
		if(ismob(loc))
			view(loc)

/obj/item/weapon/newspaper/attackby(obj/item/weapon/W, mob/user, params)
	if(istype(W, /obj/item/weapon/pen))
		if(scribble_page == curr_page)
			to_chat(user, "<span class='notice'>There's already a scribble in this page... You wouldn't want to make things too cluttered, would you?</span>")
		else
			var/s = stripped_input(user, "Write something", "Newspaper")
			if (!s)
				return
			if (!in_range(src, usr) && loc != usr)
				return
			scribble_page = curr_page
			scribble = s
			view(user)
	else
		return ..()
