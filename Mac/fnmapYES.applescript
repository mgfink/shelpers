tell application "System Events"
	tell application "System Preferences"
		reveal anchor "keyboardTab" of pane "com.apple.preference.keyboard"
		
	end tell
	
	tell window 1 of application process "System Preferences"
		--set uiElems to entire contents
		repeat until exists window 1 of application process "System Preferences" of application "System Events"
		end repeat
		click pop up button 2 of tab group 1 of window "Keyboard" of application process "System Preferences" of application "System Events"
		
		--click menu item "App Controls with Control Strip" of menu 1 of pop up button 2 of tab group 1 of window "Keyboard" of application process "System Preferences" of application "System Events"
		
		click menu item "F1, F2, etc. Keys" of menu 1 of pop up button 2 of tab group 1 of window "Keyboard" of application process "System Preferences" of application "System Events"
		--  set uiElems to entire contents
	end tell
end tell

if application "System Preferences" is running then
	tell application "System Preferences" to quit
end if
