#!/usr/bin/env zsh

typeset -gA _ZSH_PROFILE_STARTUP
typeset -gA _ZSH_PLUGIN_LOAD_TIMES
typeset -g _ZSH_PROFILE_GLOBAL_START
typeset -g _ZSH_PROFILE_ENABLED=0
typeset -g _ZSH_PROFILE_PLUGINS_ENABLED=0

zprofile_init() {
    _ZSH_PROFILE_ENABLED=1
    [[ -n "$ZSH_PROFILE_PLUGINS" ]] && _ZSH_PROFILE_PLUGINS_ENABLED=1
    zmodload zsh/datetime
    zmodload zsh/mathfunc
    zmodload zsh/zprof
    _ZSH_PROFILE_GLOBAL_START=${EPOCHREALTIME}
}

zprofile_start() {
    (( _ZSH_PROFILE_ENABLED )) || return 0
    local section=${1:?"Section name required"}
    _ZSH_PROFILE_STARTUP[$section]=${EPOCHREALTIME}
}

zprofile_end() {
    (( _ZSH_PROFILE_ENABLED )) || return 0
    local section=${1:?"Section name required"}

    [[ -n ${_ZSH_PROFILE_STARTUP[$section]} ]] || return 0

    local start_time=${_ZSH_PROFILE_STARTUP[$section]}
    local duration=$(( (EPOCHREALTIME - start_time) * 1000.0 ))
    _ZSH_PROFILE_STARTUP[$section]=$duration
}

zprofile_track_plugin_load() {
    (( _ZSH_PROFILE_ENABLED )) || return 0
    local plugin=${1:?"Plugin name required"}
    local load_type=${2:-"startup"}
    
    local key="${plugin}_${load_type}"
    [[ -n ${_ZSH_PLUGIN_LOAD_TIMES[$key]} ]] && return 0
    
    _ZSH_PLUGIN_LOAD_TIMES[$key]=${EPOCHREALTIME}
}

zprofile_record_plugin_duration() {
    (( _ZSH_PROFILE_ENABLED )) || return 0
    local plugin=${1:?"Plugin name required"}
    local load_type=${2:-"startup"}

    local key="${plugin}_${load_type}"
    [[ -n ${_ZSH_PLUGIN_LOAD_TIMES[$key]} ]] || return 0

    local start_time=${_ZSH_PLUGIN_LOAD_TIMES[$key]}
    local duration=$(( (EPOCHREALTIME - start_time) * 1000.0 ))
    _ZSH_PLUGIN_LOAD_TIMES[$key]=$duration
}

zprofile_report() {
    (( _ZSH_PROFILE_ENABLED )) || return 0

    local total_time=$(( (EPOCHREALTIME - _ZSH_PROFILE_GLOBAL_START) * 1000 ))

    print ""
    print "=========================================="
    print "     ZSH Startup Profiling Report"
    print "=========================================="
    print ""

    if (( ${#_ZSH_PROFILE_STARTUP[@]} )); then
        print "Core Initialization:"
        print -- "---------------------"

        for section in ${(ok)_ZSH_PROFILE_STARTUP}; do
            local duration=${_ZSH_PROFILE_STARTUP[$section]}
            local marker=""

            (( duration > 10 )) && marker="  <== SLOW"
            (( duration > 30 )) && marker="  <== VERY SLOW"

            printf "  %-32s %7.1fms%s\n" "$section:" "$duration" "$marker"
        done
        print ""
    fi

    if (( ${#_ZSH_PLUGIN_LOAD_TIMES[@]} )); then
        print "Plugin Load Times:"
        print -- "------------------"

        typeset -A startup_times
        typeset -A lazy_times

        for key in ${(ok)_ZSH_PLUGIN_LOAD_TIMES}; do
            local value=${_ZSH_PLUGIN_LOAD_TIMES[$key]}
            if [[ $key == *_startup ]]; then
                local plugin=${key%_startup}
                startup_times[$plugin]=$value
            elif [[ $key == *_lazy ]]; then
                local plugin=${key%_lazy}
                lazy_times[$plugin]=$value
            fi
        done

        for plugin in ${(ok)startup_times}; do
            local startup_time=${startup_times[$plugin]}
            local lazy_time=${lazy_times[$plugin]:-0}
            local marker=""

            (( startup_time > 10 )) && marker="  <== SLOW"
            (( startup_time > 30 )) && marker="  <== VERY SLOW"

            printf "  %-30s %7.1fms%s\n" "$plugin (startup):" "$startup_time" "$marker"

            if (( lazy_time > 0 )); then
                local lazy_marker=""
                (( lazy_time > 10 )) && lazy_marker="  <== SLOW"
                (( lazy_time > 30 )) && lazy_marker="  <== VERY SLOW"

                if (( lazy_time > 1000000000 )); then
                    printf "  %-30s (deferred)\n" "  └─ (actual load):"
                else
                    printf "  %-30s %7.1fms%s\n" "  └─ (actual load):" "$lazy_time" "$lazy_marker"
                fi
            fi
        done

        local deferred_plugins=()
        for plugin in ${(ok)lazy_times}; do
            [[ -n ${startup_times[$plugin]} ]] && continue
            local value=${lazy_times[$plugin]}
            if (( value > 1000000000 )); then
                deferred_plugins+=("$plugin")
            else
                local marker=""
                (( value > 10 )) && marker="  <== SLOW"
                (( value > 30 )) && marker="  <== VERY SLOW"
                deferred_plugins+=("$plugin:$value:$marker")
            fi
        done

        if (( ${#deferred_plugins[@]} )); then
            print "  Deferred plugins not yet loaded:"
            for plugin_info in "${deferred_plugins[@]}"; do
                local plugin="$plugin_info"
                local value=""
                local marker=""
                if [[ $plugin_info == *:* ]]; then
                    plugin="${plugin_info%%:*}"
                    local rest="${plugin_info#*:}"
                    value="${rest%%:*}"
                    marker="${rest#*:}"
                fi
                if [[ -z "$value" ]]; then
                    printf "  %-32s %s\n" "${plugin}:" "(deferred)"
                else
                    printf "  %-32s %7.1fms%s\n" "${plugin}:" "$value" "$marker"
                fi
            done
        fi
        print ""
    fi

    print "=========================================="
    printf "  TOTAL STARTUP TIME: %7.1fms\n" "$total_time"
    print "=========================================="

    print ""
    print "=========================================="
    print "     Function-Level Profiling (zprof)"
    print "=========================================="
    print ""
    zprof
    print ""
}

zprofile_load_plugin() {
    (( _ZSH_PROFILE_ENABLED )) || return 0

    local mode=${1}
    local plugin=${2}
    local plugin_name=${${plugin##*/}%@*}

    if [[ $mode == "lazy" ]]; then
        zprofile_track_plugin_load "$plugin_name" "lazy"
    else
        zprofile_track_plugin_load "$plugin_name" "startup"
    fi
}

zprofile_plugin_loaded() {
    (( _ZSH_PROFILE_ENABLED )) || return 0
    
    local mode=${1}
    local plugin=${2}
    local plugin_name=${${plugin##*/}%@*}
    
    if [[ $mode == "lazy" ]]; then
        zprofile_record_plugin_duration "$plugin_name" "lazy"
    else
        zprofile_record_plugin_duration "$plugin_name" "startup"
    fi
}
