import consumer from "./consumer";

// Subscribe to system notifications
const systemNotificationChannel = consumer.subscriptions.create(
    "SystemNotificationChannel",
    {
        connected() {
            console.log("Connected to SystemNotificationChannel");
        },

        disconnected() {
            console.log("Disconnected from SystemNotificationChannel");
        },

        received(data) {
            console.log("System notification received:", data);

            // Handle different types of system notifications
            if (data.type === "clear_cookies_and_reload") {
                this.handleClearCookiesAndReload(data);
            } else {
                console.log("Unknown system notification type:", data.type);
            }
        },

        handleClearCookiesAndReload(data) {
            console.log(
                "Clearing cookies and reloading due to invalid session:",
                data.reason,
            );

            // Add a flag to prevent multiple simultaneous clears
            if (sessionStorage.getItem("clearing_cookies") === "true") {
                console.log("Cookie clearing already in progress, skipping");
                return;
            }

            sessionStorage.setItem("clearing_cookies", "true");

            // Clear all cookies for this domain
            const cookies = document.cookie.split(";");
            for (const c of cookies) {
                document.cookie = c
                    .replace(/^ +/, "")
                    .replace(
                        /=.*/,
                        "=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/",
                    );
            }

            console.log("Cookies cleared, reloading page...");

            // Reload the page to get a fresh session
            globalThis.location.reload();
        },
    },
);

export default systemNotificationChannel;
