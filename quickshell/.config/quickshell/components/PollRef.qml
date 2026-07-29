import QtQuick

QtObject {
    id: pollRef

    required property var service

    Component.onCompleted: {
        if (service && typeof service.registerPollConsumer === "function")
            service.registerPollConsumer();
    }

    Component.onDestruction: {
        if (service && typeof service.unregisterPollConsumer === "function")
            service.unregisterPollConsumer();
    }
}
