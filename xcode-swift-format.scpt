set current_document_path to ""

tell application "Xcode"
	set last_word_in_main_window to (word -1 of (get name of window 1))
	if (last_word_in_main_window is "Edited") then
		tell application "System Events" to keystroke "s" using command down
		delay 1
	end if
	set last_word_in_main_window to (word -1 of (get name of window 1))
	set current_document to document 1 whose name ends with last_word_in_main_window
	set current_document_path to path of current_document
end tell
if (current_document_path is not "") then
	do shell script "/opt/homebrew/bin/swift-format format -i " & current_document_path
end if
