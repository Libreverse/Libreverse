// Secure permission handling for iframes
(function () {
    "use strict";

    // Function to request permissions if needed
    function requestPermissionsIfNeeded() {
        const permissions = [
            "camera",
            "microphone",
            "geolocation",
            "accelerometer",
            "gyroscope",
            "magnetometer",
        ];

        for (const permission of permissions) {
            if (navigator.permissions && navigator.permissions.query) {
                navigator.permissions
                    .query({ name: permission })
                    .then((result) => {
                        if (result.state === "prompt") {
                            // Permission needs to be requested
                            console.log(`Requesting ${permission} permission`);
                            // The actual API usage will trigger the permission prompt
                        }
                    })
                    .catch((error) => {
                        console.warn(
                            `Permission query failed for ${permission}:`,
                            error,
                        );
                    });
            }
        }
    }

    // Request on load and user interaction
    window.addEventListener("load", requestPermissionsIfNeeded);
    document.addEventListener("click", requestPermissionsIfNeeded, {
        once: true,
    });
    document.addEventListener("keydown", requestPermissionsIfNeeded, {
        once: true,
    });
})();
