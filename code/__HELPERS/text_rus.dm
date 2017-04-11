// ��� ����� ��������, ��������������� ��� ������ � ����������.
// � ���������, ������� ����� ����, ��������� "�", ��������� ������ ���.
// ������������ ���� �������. ������ � ������ �� ��.

/*
���� ����� "�":

��� ���������� ����� ����� ��� ������� 255, � �� �������������� � BYOND ��� ����� ���������� �����.
� ���������, "�" (0xFF) ������������ ��� ������ ���� "��������" \proper, \improper, \red, \green � �������� ��.
��, BYOND ����� ���� ����������� ������������ ��������� � �������� ���������� ��� ASCII. ����� �������-�������������!

����� "�" ������������ ���������, �� �������� � �� �������� ������� ���� � ������, ���������� �������� � HTML-����� �������.
������ ���� ������� ������ "�������" ������. ������ ��� �� ������������, �� ����� ������ "�" �� ��� ��� �������� � ���� "�~" ��� "y~", ��� "~" - �����.
������� ����� ������ �������, \proper � \improper, �� ���� �������.


����� "�" �� ������ (input(), ������� �������� verbs, �������� �� ������) ���������� ����������:
  sanitize_russian() - �������� "�" � ������� �������.
  rhtml_encode() - �������� "�", ������� ������� � �������� HTML ������� ���������� ������. ������� �� ����������� ������.

������ ���������� �� "&#x44F;" - HTML ��� "�", �������� Unicode.
���� �������� ������� HTML-��������, �� ������� �������� ����� ��� ����������.

�� ������� � ����� "�" ��� �������� ����������� � stripped_input(), stripped_multiline_input() � reject_bad_text().
��� ��������� ����� ����� ��� �����, ������������ ��������. ��������� ����� ������ �������.

��� � reject_bad_text() ���������������� ������� "//if(127 to 255) return", ������� ���������� ��������� ����� ��������� �����.


���� ��� ���� ������ �������:
  russian_html2text(msg) - �������� "&#x44F;" �� "&#255;", �������� CP1251.

����� �� ������, ��� ��� � ��-HTML ����� ����������� ������ ��������� ������ ��������� �������, � ��� � ��� CP1251.
�� ������� ������������ � to_chat() � �����, ��� ����� ������� ������� ����� � ���������� ����� input().
��� Win-1251 ������������ � "name" ��������, �� ��������� � "name" � ����� ������ �������� ����� �������. ������ ����� ����� - ����� �����������.
*/

/*
���� ����� TG UI:

!!!WIP!!!

*/


// ������� ��������� "�������" � ������.
/proc/strip_macros(t)
	t = replacetext(t, "\proper", "")
	t = replacetext(t, "\improper", "")
	return t

// ������ "�" �� ���, ������� ������ �������.
/proc/sanitize_russian(t)
	t = strip_macros(t)
	return replacetext(t, "�", "&#x44F;")

// ������ �������� "�" � Unicode �� CP1251
/proc/russian_html2text(t)
	return replacetext(t, "&#x44F;", "&#255;")

// ������ �������� "�" � CP1251 �� Unicode
/proc/russian_text2html(t)
	return replacetext(t, "&#255;", "&#x44F;")

// ������� �������, ������ "�" �� ��� � �������� HTML-�������.
// ������� �� ����������� ����� ����� ��� ������� ������ ��� ���� ���, �� ������ ����� ����.
/proc/rhtml_encode(t)
	t = strip_macros(t)
	var/list/c = splittext(t, "�")
	if(c.len == 1)
		return t
	var/out = ""
	var/first = 1
	for(var/text in c)
		if(!first)
			out += "&#x44F;"
		first = 0
		out += html_encode(text)
	return out

// �� ���� ������ ���� �������� ������� �� "�" � ������ HTML-������ ������� �� �������.
// �� ���� �� ������������, ��� �����?
/proc/rhtml_decode(var/t)
	t = replacetext(t, "&#x44F;", "�")
	t = replacetext(t, "&#255;", "�")
	t = html_decode(t)
	return t


/proc/char_split(t)
	. = list()
	for(var/x in 1 to length(t))
		. += copytext(t,x,x+1)

/proc/uppertext_uni(text)
	var/rep = "�"
	var/index = findtext(text, "�")
	while(index)
		text = copytext(text, 1, index) + rep + copytext(text, index + 1)
		index = findtext(text, "�")
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a > 223)
			t += ascii2text(a - 32)
		else if (a == 184)
			t += ascii2text(168)
		else t += ascii2text(a)
	return t

/proc/lowertext_uni(text)
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a > 191 && a < 224)
			t += ascii2text(a + 32)
		else if (a == 168)
			t += ascii2text(184)
		else t += ascii2text(a)
	return t

/proc/ruscapitalize(t)
	var/s = 2
	if (copytext(t,1,2) == ";")
		s += 1
	else if (copytext(t,1,2) == ":")
		if(copytext(t,3,4) == " ")
			s+=3
		else
			s+=2
	return upperrustext(copytext(t, 1, s)) + copytext(t, s)

/proc/upperrustext(text)
	var/rep = "&#223;"
	var/index = findtext(text, "�")
	while(index)
		text = copytext(text, 1, index) + rep + copytext(text, index + 1)
		index = findtext(text, "�")
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a > 223)
			t += ascii2text(a - 32)
		else if (a == 184)
			t += ascii2text(168)
		else t += ascii2text(a)
	return t

/proc/lowerrustext(text)
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a > 191 && a < 224)
			t += ascii2text(a + 32)
		else if (a == 168)
			t += ascii2text(184)
		else t += ascii2text(a)
	return t

/proc/capitalize_uni(var/t)
	var/s = 2
	if (copytext(t,1,2) == ";")
		s += 1
	else if (copytext(t,1,2) == ":")
		if(copytext(t,3,4) == " ")
			s+=3
		else
			s+=2
	return pointization(uppertext_uni(copytext(t, 1, s)) + copytext(t, s))

/proc/pointization(text)
	if (!text)
		return
	if (copytext(text,1,2) == "*") //Emotes allowed.
		return text
	if (copytext(text,-1) in list("!", "?", "."))
		return text
	text += "."
	return text

/proc/intonation(text)
	if (copytext(text,-1) == "!")
		text = "<b>[text]</b>"
	return text


var/list/rus_unicode_conversion = list(
	"�" = "&#x410;", "�" = "&#x430;",
	"�" = "&#x411;", "�" = "&#x431;",
	"�" = "&#x412;", "�" = "&#x432;",
	"�" = "&#x413;", "�" = "&#x433;",
	"�" = "&#x414;", "�" = "&#x434;",
	"�" = "&#x415;", "�" = "&#x435;",
	"�" = "&#x416;", "�" = "&#x436;",
	"�" = "&#x417;", "�" = "&#x437;",
	"�" = "&#x418;", "�" = "&#x438;",
	"�" = "&#x419;", "�" = "&#x439;",
	"�" = "&#x41A;", "�" = "&#x43A;",
	"�" = "&#x41B;", "�" = "&#x43B;",
	"�" = "&#x41C;", "�" = "&#x43C;",
	"�" = "&#x41D;", "�" = "&#x43D;",
	"�" = "&#x41E;", "�" = "&#x43E;",
	"�" = "&#x41F;", "�" = "&#x43F;",
	"�" = "&#x420;", "�" = "&#x440;",
	"�" = "&#x421;", "�" = "&#x441;",
	"�" = "&#x422;", "�" = "&#x442;",
	"�" = "&#x423;", "�" = "&#x443;",
	"�" = "&#x424;", "�" = "&#x444;",
	"�" = "&#x425;", "�" = "&#x445;",
	"�" = "&#x426;", "�" = "&#x446;",
	"�" = "&#x427;", "�" = "&#x447;",
	"�" = "&#x428;", "�" = "&#x448;",
	"�" = "&#x429;", "�" = "&#x449;",
	"�" = "&#x42A;", "�" = "&#x44A;",
	"�" = "&#x42B;", "�" = "&#x44B;",
	"�" = "&#x42C;", "�" = "&#x44C;",
	"�" = "&#x42D;", "�" = "&#x44D;",
	"�" = "&#x42E;", "�" = "&#x44E;",
	"�" = "&#x42F;", "�" = "&#x44F;",

	"�" = "&#x401;", "�" = "&#x451;"
	)

// �������� ��� ������� ������� � HTML-���� Unicode, ������� ������ �������.
/proc/russian_text2unicode(text)
	text = strip_macros(text)
	text = russian_text2html(text)

	for(var/s in rus_unicode_conversion)
		text = replacetext(text, s, rus_unicode_conversion[s])

	return text

