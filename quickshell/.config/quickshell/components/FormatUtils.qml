pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    /// Format raw bytes into human-readable size (e.g. "4.2G", "512M")
    function formatBytes(bytes) {
        if (bytes >= 1099511627776)
            return (bytes / 1099511627776).toFixed(1) + "T";
        if (bytes >= 1073741824)
            return (bytes / 1073741824).toFixed(1) + "G";
        if (bytes >= 1048576)
            return (bytes / 1048576).toFixed(0) + "M";
        return bytes + "B";
    }

    /// Format megabytes into human-readable memory (e.g. "15.4GB", "512MB")
    function formatMemory(mb) {
        if (mb >= 1024)
            return (mb / 1024).toFixed(1) + "GB";
        return mb + "MB";
    }

    /// Format bytes-per-second into human-readable speed (e.g. "1.2M/s")
    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024)
            return Math.round(bytesPerSec) + "B/s";
        if (bytesPerSec < 1024 * 1024)
            return (bytesPerSec / 1024).toFixed(1) + "K/s";
        return (bytesPerSec / 1024 / 1024).toFixed(1) + "M/s";
    }
}
