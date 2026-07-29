pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property bool ready: false
    property real currentTemp: 0
    property string currentCondition: ""
    property string currentIcon: "󰖐"
    property int currentHumidity: 0
    property real currentWindSpeed: 0
    property real currentFeelsLike: 0
    property string cityName: ""
    property var forecast: []
    property var lastUpdated: null
    property bool useFahrenheit: Config.weatherUseFahrenheit
    property bool fetching: false
    property int _retryCount: 0
    property var _pendingGeo: null

    // ── Polling control (consumer-visibility) ──
    property int _pollConsumers: 0
    readonly property bool pollingActive: _pollConsumers > 0

    function registerPollConsumer() {
        _pollConsumers++;
    }
    function unregisterPollConsumer() {
        _pollConsumers = Math.max(0, _pollConsumers - 1);
    }

    // ── Cache path ──
    readonly property string _cachePath: Quickshell.env("HOME") + "/.config/quickshell/weather_cache.json"

    // ── Public helpers ──

    function refresh() {
        _resolveLocation();
    }

    function iconForCode(wmoCode) {
        switch (wmoCode) {
        case 0:
        case 1:
            return "󰖨";
        case 2:
            return "󰖕";
        case 3:
            return "󰖐";
        case 45:
        case 48:
            return "󰖑";
        case 51:
        case 53:
            return "󰖗";
        case 55:
            return "󰖗";
        case 61:
            return "󰖗";
        case 63:
        case 65:
            return "󰖘";
        case 71:
        case 73:
        case 75:
            return "󰼵";
        case 80:
            return "󰖗";
        case 81:
        case 82:
            return "󰖘";
        case 85:
        case 86:
            return "󰼵";
        case 95:
        case 96:
        case 99:
            return "󰖝";
        default:
            return "󰖐";
        }
    }

    function conditionForCode(wmoCode) {
        switch (wmoCode) {
        case 0:
            return "Clear sky";
        case 1:
            return "Mainly clear";
        case 2:
            return "Partly cloudy";
        case 3:
            return "Overcast";
        case 45:
            return "Foggy";
        case 48:
            return "Rime fog";
        case 51:
            return "Light drizzle";
        case 53:
            return "Drizzle";
        case 55:
            return "Dense drizzle";
        case 61:
            return "Slight rain";
        case 63:
            return "Moderate rain";
        case 65:
            return "Heavy rain";
        case 71:
            return "Light snow";
        case 73:
            return "Snow";
        case 75:
            return "Heavy snow";
        case 80:
            return "Light showers";
        case 81:
            return "Showers";
        case 82:
            return "Heavy showers";
        case 85:
            return "Light snow showers";
        case 86:
            return "Snow showers";
        case 95:
            return "Thunderstorm";
        case 96:
            return "Thunderstorm";
        case 99:
            return "Severe storm";
        default:
            return "Unknown";
        }
    }

    function tempString(temp) {
        if (root.useFahrenheit)
            return Math.round(_toF(temp)) + "\u00B0F";
        return Math.round(temp) + "\u00B0C";
    }

    function _toF(celsius) {
        return celsius * 9 / 5 + 32;
    }

    function _dayName(dateStr) {
        var d = new Date(dateStr);
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return days[d.getDay()];
    }

    // ── Location resolution ──

    function _resolveLocation() {
        root.fetching = true;

        // Tier 1: explicit lat/lon
        if (Config.weatherLocationLat !== 0 && Config.weatherLocationLon !== 0) {
            _fetchWeather(Config.weatherLocationLat, Config.weatherLocationLon);
            return;
        }

        // Tier 2: city name geocoding
        if (Config.weatherCity !== "") {
            var encoded = encodeURIComponent(Config.weatherCity);
            geoCityProc.command = ["curl", "-s", "--max-time", "10", "https://geocoding-api.open-meteo.com/v1/search?name=" + encoded + "&count=1"];
            geoCityProc.running = true;
            return;
        }

        // Tier 3: GeoIP fallback
        geoIpProc.running = true;
    }

    Process {
        id: geoCityProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(data.toString());
                    if (parsed.results && parsed.results.length > 0) {
                        var r = parsed.results[0];
                        root.cityName = r.name || "";
                        root._fetchWeather(r.latitude, r.longitude);
                    } else {
                        root._onFetchError();
                    }
                } catch (e) {
                    root._onFetchError();
                }
            }
        }
        onExited: function (code, status) {
            if (code !== 0)
                root._onFetchError();
        }
    }

    Process {
        id: geoIpProc
        running: false
        command: ["curl", "-s", "--max-time", "10", "https://ipapi.co/json/"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(data.toString());
                    if (parsed.latitude !== undefined && parsed.longitude !== undefined) {
                        root.cityName = parsed.city || "";
                        root._fetchWeather(parsed.latitude, parsed.longitude);
                    } else {
                        root._onFetchError();
                    }
                } catch (e) {
                    root._onFetchError();
                }
            }
        }
        onExited: function (code, status) {
            if (code !== 0)
                root._onFetchError();
        }
    }

    // ── Weather fetch ──

    function _fetchWeather(lat, lon) {
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,apparent_temperature" + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=7";
        weatherProc.command = ["curl", "-s", "--max-time", "10", url];
        weatherProc.running = true;
    }

    Process {
        id: weatherProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(data.toString());
                    if (!parsed.current || !parsed.daily) {
                        root._onFetchError();
                        return;
                    }

                    var c = parsed.current;
                    root.currentTemp = c.temperature_2m || 0;
                    root.currentHumidity = c.relative_humidity_2m || 0;
                    root.currentWindSpeed = c.wind_speed_10m || 0;
                    root.currentFeelsLike = c.apparent_temperature || 0;

                    var code = c.weather_code || 0;
                    root.currentCondition = root.conditionForCode(code);
                    root.currentIcon = root.iconForCode(code);

                    var d = parsed.daily;
                    var fc = [];
                    for (var i = 0; i < d.time.length; i++) {
                        fc.push({
                            "date": d.time[i],
                            "icon": root.iconForCode(d.weather_code[i] || 0),
                            "high": d.temperature_2m_max[i] || 0,
                            "low": d.temperature_2m_min[i] || 0,
                            "dayName": root._dayName(d.time[i])
                        });
                    }
                    root.forecast = fc;
                    root.lastUpdated = new Date();
                    root.ready = true;
                    root._retryCount = 0;
                    root.fetching = false;
                    root._writeCache(data.toString());
                } catch (e) {
                    root._onFetchError();
                }
            }
        }
        onExited: function (code, status) {
            if (code !== 0)
                root._onFetchError();
        }
    }

    function _onFetchError() {
        root.fetching = false;
        root._retryCount++;
        if (root._retryCount >= 3) {
            retryBackoff.interval = Math.min(30 * 60 * 1000, 60000 * Math.pow(2, root._retryCount - 3));
            retryBackoff.start();
        }
    }

    Timer {
        id: retryBackoff
        interval: 60000
        onTriggered: {
            if (root.pollingActive)
                root.refresh();
        }
    }

    // ── Cache read/write ──

    function _writeCache(json) {
        var escaped = json.replace(/'/g, "'\\''");
        cacheWriteProc.command = ["bash", "-c", "echo '" + escaped + "' > '" + root._cachePath + "'"];
        cacheWriteProc.running = true;
    }

    Process {
        id: cacheWriteProc
        running: false
        command: ["true"]
    }

    Component.onCompleted: {
        cacheReadProc.running = true;
    }

    Process {
        id: cacheReadProc
        running: false
        command: ["bash", "-c", "cat '" + root._cachePath + "' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = data.toString().trim();
                    if (!raw)
                        return;
                    var parsed = JSON.parse(raw);
                    if (!parsed.current || !parsed.daily)
                        return;

                    var c = parsed.current;
                    root.currentTemp = c.temperature_2m || 0;
                    root.currentHumidity = c.relative_humidity_2m || 0;
                    root.currentWindSpeed = c.wind_speed_10m || 0;
                    root.currentFeelsLike = c.apparent_temperature || 0;

                    var code = c.weather_code || 0;
                    root.currentCondition = root.conditionForCode(code);
                    root.currentIcon = root.iconForCode(code);

                    var d = parsed.daily;
                    var fc = [];
                    for (var i = 0; i < d.time.length; i++) {
                        fc.push({
                            "date": d.time[i],
                            "icon": root.iconForCode(d.weather_code[i] || 0),
                            "high": d.temperature_2m_max[i] || 0,
                            "low": d.temperature_2m_min[i] || 0,
                            "dayName": root._dayName(d.time[i])
                        });
                    }
                    root.forecast = fc;
                    root.ready = true;
                } catch (e) {
                    // Cache invalid — will fetch fresh data when polling starts
                }
            }
        }
    }

    // ── Refresh timer ──

    Timer {
        id: refreshTimer
        interval: Config.weatherRefreshMinutes * 60000 + Math.round(Math.random() * 30000)
        running: root.pollingActive
        repeat: true
        triggeredOnStart: root.pollingActive
        onTriggered: root.refresh()
    }
}
