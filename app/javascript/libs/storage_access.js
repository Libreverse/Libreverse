// Secure IndexedDB access for iframes
(function () {
    // Function to request storage access if needed
    function requestStorageAccessIfNeeded() {
        if (
            document.requestStorageAccess && // Check if we can access IndexedDB
            typeof indexedDB !== "undefined"
        ) {
            // Try to open a test database to see if access is granted
            var request = indexedDB.open("test_access", 1);
            request.addEventListener('error', function () {
                // If error, perhaps access is denied, try to request
                document
                    .requestStorageAccess()
                    .then(function () {
                        console.log("Storage access granted");
                        // Now IndexedDB should be accessible
                    })
                    .catch(function () {
                        console.warn("Storage access denied");
                    });
            });
            request.addEventListener('success', function () {
                // Access is fine
                request.result.close();
            });
        }
    }

    // Request on load
    window.addEventListener("load", requestStorageAccessIfNeeded);

    // Also request on user interaction to satisfy user activation requirement
    document.addEventListener("click", requestStorageAccessIfNeeded, {
        once: true,
    });
    document.addEventListener("keydown", requestStorageAccessIfNeeded, {
        once: true,
    });
})();
