import http from "k6/http";
import { sleep } from "k6";

export let options = {
    stages: [
        { duration: "15s", target: 5 }, // Ramp up to 5 VUs
        { duration: "15s", target: 10 }, // Ramp up to 10 VUs
        { duration: "15s", target: 20 }, // Ramp up to 20 VUs
        { duration: "15s", target: 50 }, // Ramp up to 50 VUs
        { duration: "15s", target: 0 }, // Ramp down
    ],
    thresholds: {
        http_req_failed: [
            { threshold: "rate<0.01", abortOnFail: true }, // Stop if error rate > 1%
        ],
        http_req_duration: [
            { threshold: "p(95)<500", abortOnFail: true }, // Stop if p(95) > 500ms
        ],
    },
    summaryTrendStats: ["avg", "min", "med", "max", "p(95)", "p(99)"],
};

export default function () {
    http.get("https://libreverse.geor.me"); // Replace with your app's URL
    sleep(0.1); // Minimal delay for realistic pacing
}
