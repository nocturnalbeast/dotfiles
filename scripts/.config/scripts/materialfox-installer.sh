#!/bin/sh

NAME=$(basename "$0")
VER="0.1"

function echo_message() {

	local COLOR=$1;
	local MESSAGE=$2;
	if ! [[ $COLOR =~ '^[0-9]$' ]] ; then
		case $(echo -e $COLOR | tr '[:upper:]' '[:lower:]') in
			error) COLOR=1 ;;
			success) COLOR=2 ;;
			warning) COLOR=3 ;;
			info) COLOR=4 ;;
			question) COLOR=5 ;;
			normal) COLOR=6 ;;
			*) COLOR=7 ;;
		esac
	fi
	tput bold;
	tput setaf $COLOR;
	echo -e " -- $MESSAGE\n";
	tput sgr0;

}

function usage() {

echo_message white "$NAME -- Version $VER

Usage: $NAME [OPTIONS]

Options:
  -h, --help        Show this help dialog
  -v, --version     Display script version
  -i, --install     Install MaterialFox
  -r, --remove      Remove MaterialFox
  -l, --light       Activate the light theme
  -d, --dark        Activate the dark theme
"

}


for arg in "$@"; do
	case $arg in
		-h|--help)
			usage
			exit 0
			;;
		-v|--version)
			echo_message info "$NAME -- Version $VER"
			exit 0
			;;
		-i|--install)
			echo_message question "This will overwrite any userChome modifications made to Firefox. Do you want to continue?"
			read yn
			case $yn in
				[Yy]* )
					echo_message info "Killing all Firefox windows..."
					pkill firefox
					sleep 5 # just a safety measure
					echo_message info "Downloading MaterialFox..."
					git clone https://github.com/muckSponge/MaterialFox
					echo_message info "Obtaining profile directory..."
					PROFILE_DIR=$(grep "Path" ~/.mozilla/firefox/profiles.ini | awk -F '=' '{print $2}')
					echo_message info "Your profile directory is $PROFILE_DIR"
					echo_message info "Removing existing userChrome modifications..."
					rm -rf ~/.mozilla/firefox/$PROFILE_DIR/chrome
					echo_message info "Installing MaterialFox..."
					mv MaterialFox/chrome ~/.mozilla/firefox/$PROFILE_DIR/
					rm -rf MaterialFox
					if grep -q "svg.context-properties.content.enabled" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
					then
						sed -i -e "s/^user_pref\(\"svg\.context-properties\.content\.enabled\", \(true\|false\)\);$/user_pref\(\"svg\.context-properties\.content\.enabled\", true\);/" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
					else
						echo "user_pref(\"svg.context-properties.content.enabled\", true);" >> ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
					fi
					echo_message question "Do you want Firefox to replicate Chrome-like behavior for clipped tabs?"
					read yn
					case $yn in
						[Yy]* )
							if grep -q "browser.tabs.tabClipWidth" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
							then
								sed -i -e "s/^user_pref\(\"browser\.tabs\.tabClipWidth\", [0-9]+\);$/user_pref\(\"browser\.tabs\.tabClipWidth\", 83\);/" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
							else
								echo "user_pref(\"browser.tabs.tabClipWidth\", 83);" >> ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
							fi
							;;
						[Nn]* )
							echo_message error "Clipped tabs will retain their behavior."
							;;
						* )
							echo_message error "Clipped tabs will retain their behavior."
							;;
					esac
					echo_message question "Do you want to allow tabs to shrink more?"
					read yn
					case $yn in
						[Yy]* )
							echo "user_pref(\"materialFox.reduceTabOverflow\", true);" >> ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
							;;
						[Nn]* )
							echo_message error "Tabs won't be shortened."
							;;
						* )
							echo_message error "Tabs won't be shortened."
							;;
					esac
					echo_message question "Do you want the not secure label on the addressbar for HTTP websites?"
					read yn
					case $yn in
						[Yy]* )
							if grep -q "security.insecure_connection_text.enabled" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
							then
								sed -i -e "s/^user_pref\(\"security\.insecure_connection_text\.enabled\", \(true\|false\)\);$/user_pref\(\"security\.insecure_connection_text\.enabled\", true\);/" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
							else
								echo "user_pref(\"security.insecure_connection_text.enabled\", true);" >> ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
							fi
							;;
						[Nn]* )
							echo_message error "Not secure label not set."
							;;
						* )
							echo_message error "Not secure label not set."
							;;
					esac
					;;
				[Nn]* )
					echo_message error "MaterialFox not installed. Installation aborted."
					;;
				* )
					echo_message warning "Please answer yes or no."
					;;
			esac
			;;
		-r|--remove)
			echo_message question "This will remove any userChome modifications made to Firefox alongside removing MaterialFox. Do you want to continue?"
			read yn
			case $yn in
				[Yy]* )
					echo_message info "Killing all Firefox windows..."
					pkill firefox
					sleep 5 # just a safety measure
					echo_message info "Obtaining profile directory..."
					PROFILE_DIR=$(grep "Path" ~/.mozilla/firefox/profiles.ini | awk -F '=' '{print $2}')
					echo_message info "Your profile directory is $PROFILE_DIR"
					echo_message info "Removing MaterialFox and all other userChrome modifications..."
					rm -rf ~/.mozilla/firefox/$PROFILE_DIR/chrome
					echo_message info "Removing additional preferences..."
					sed -i -e "/^user_pref\(\"security\.insecure_connection_text\.enabled\", true\);$/d" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
					sed -i -e "/^user_pref\(\"materialFox\.reduceTabOverflow\", true\);$/d" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
					sed -i -e "s/^user_pref\(\"browser\.tabs\.tabClipWidth\", 83\);$/user_pref\(\"browser\.tabs\.tabClipWidth\", 144\);/" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
					sed -i -e "/^user_pref\(\"svg\.context-properties\.content\.enabled\", true\);$/d" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
					;;
				[Nn]* )
					echo_message success "MaterialFox wasn't removed, hooray!"
					;;
				* )
					echo_message warning "Please answer yes or no."
					;;
			esac
			;;
		-l|--light)
			echo_message info "Killing all Firefox windows..."
			pkill firefox
			sleep 5 # just a safety measure
			echo_message info "Obtaining profile directory..."
			PROFILE_DIR=$(grep "Path" ~/.mozilla/firefox/profiles.ini | awk -F '=' '{print $2}')
			echo_message info "Your profile directory is $PROFILE_DIR"
			echo_message info "Activating the light theme for Firefox..."
			if grep -q "lightweightThemes.selectedThemeID" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
			then
				sed -i -e "s/^user_pref\(\"lightweightThemes\.selectedThemeID\", \".*\"\);$/user_pref\(\"lightweightThemes\.selectedThemeID\", \"firefox-compact-light@mozilla\.org\"\);/" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
			else
				echo "user_pref(\"lightweightThemes.selectedThemeID\", \"firefox-compact-light@mozilla.org\");" >> ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
			fi
			sed -i -e "s/^user_pref\(\"lightweightThemes\.selectedThemeID\", \".*\"\);$/user_pref\(\"lightweightThemes\.selectedThemeID\", \"firefox-compact-light@mozilla\.org\"\);/" ~/.mozilla/firefox/prefs.js

			;;
		-d|--dark)
			echo_message info "Killing all Firefox windows..."
			pkill firefox
			sleep 5 # just a safety measure
			echo_message info "Obtaining profile directory..."
			PROFILE_DIR=$(grep "Path" ~/.mozilla/firefox/profiles.ini | awk -F '=' '{print $2}')
			echo_message info "Your profile directory is $PROFILE_DIR"
			echo_message info "Activating the dark theme for Firefox..."
			if grep -q "lightweightThemes.selectedThemeID" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
			then
				sed -i -e "s/^user_pref\(\"lightweightThemes\.selectedThemeID\", \".*\"\);$/user_pref\(\"lightweightThemes\.selectedThemeID\", \"firefox-compact-dark@mozilla\.org\"\);/" ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
			else
				echo "user_pref(\"lightweightThemes.selectedThemeID\", \"firefox-compact-dark@mozilla.org\");" >> ~/.mozilla/firefox/$PROFILE_DIR/prefs.js
			fi
			sed -i -e "s/^user_pref\(\"lightweightThemes\.selectedThemeID\", \".*\"\);$/user_pref\(\"lightweightThemes\.selectedThemeID\", \"firefox-compact-dark@mozilla\.org\"\);/" ~/.mozilla/firefox/prefs.js
			;;
		*)
			echo_message error "Option does not exist: $arg"
			echo_message error "Use $NAME -h for help."
			exit 2
			;;
	esac
done
