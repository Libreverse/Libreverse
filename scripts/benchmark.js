import http from "k6/http";
import { sleep } from "k6";

export let options = {
    vus: 50, // 50 virtual users
    duration: "30s", // Run for 30 seconds
};

export default function () {
    http.get("https://libreverse.geor.me");
    sleep(1); // Simulate user think time
}
