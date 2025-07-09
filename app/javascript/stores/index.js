import { createStore } from "stimulus-store";

// App-wide theme and UI state
export const themeStore = createStore({
    name: "theme",
    type: Object,
    initialValue: {
        darkMode: false,
        glassEnabled: true,
        animationsEnabled: true,
        parallaxEnabled: true,
        currentTheme: "default",
    },
});

// Glass effect configuration store
export const glassConfigStore = createStore({
    name: "glassConfig",
    type: Object,
    initialValue: {
        borderRadius: 20,
        tintOpacity: 0.12,
        glassType: "rounded",
        parallaxSpeed: 1,
        parallaxOffset: 0,
        syncWithParallax: true,
        backgroundParallaxSpeed: -2,
    },
});

// Navigation state store
export const navigationStore = createStore({
    name: "navigation",
    type: Object,
    initialValue: {
        currentPath: globalThis.location.pathname,
        sidebarOpen: false,
        navItems: [],
        activeItem: undefined,
    },
});

// Instance settings state store
export const instanceSettingsStore = createStore({
    name: "instanceSettings",
    type: Object,
    initialValue: {
        automoderation: false,
        eeaMode: false,
        forceSsl: false,
        noSsl: false,
        railsLogLevel: "info",
        allowedHosts: "",
        corsOrigins: "",
        port: 3000,
        adminEmail: "",
        isDirty: false,
        isLoading: false,
    },
});

// Toast notification state store
export const toastStore = createStore({
    name: "toast",
    type: Object,
    initialValue: {
        toasts: [],
        nextId: 1,
        defaultTimeout: 5000,
        maxToasts: 5,
    },
});

// Experience/content state store
export const experienceStore = createStore({
    name: "experience",
    type: Object,
    initialValue: {
        currentExperience: undefined,
        isLoading: false,
        uploadProgress: 0,
    },
});

// Search and filter state store
export const searchStore = createStore({
    name: "search",
    type: Object,
    initialValue: {
        query: "",
        filters: {},
        results: [],
        isLoading: false,
        pagination: {
            page: 1,
            totalPages: 1,
            perPage: 20,
        },
    },
});
