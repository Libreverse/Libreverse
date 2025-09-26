import http from "k6/http";
import { sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

// Custom metrics for better visualization
let requestsPerSecond = new Rate("requests_per_second");
let responseTimeVsLoad = new Trend("response_time_vs_load");

export let options = {
    stages: [
        { duration: "30s", target: 1 }, // 1 RPS
        { duration: "30s", target: 5 }, // 5 RPS
        { duration: "30s", target: 10 }, // 10 RPS
        { duration: "30s", target: 20 }, // 20 RPS
        { duration: "30s", target: 30 }, // 30 RPS
        { duration: "30s", target: 40 }, // 40 RPS
        { duration: "30s", target: 50 }, // 50 RPS
        { duration: "30s", target: 25 }, // Scale down to 25 RPS
        { duration: "30s", target: 10 }, // Scale down to 10 RPS
        { duration: "30s", target: 0 }, // Ramp down
    ],
    thresholds: {
        // Remove abort conditions to collect full data
        http_req_duration: ["p(95)<2000"], // Just for monitoring, no abort
        http_req_failed: ["rate<0.05"], // Allow up to 5% failures
    },
    summaryTrendStats: ["avg", "min", "med", "max", "p(90)", "p(95)", "p(99)"],
    // Output detailed results
    summaryTimeUnit: "ms",
};

export default function () {
    let response = http.get("http://localhost:3000");

    // Record custom metrics for analysis
    requestsPerSecond.add(1);
    responseTimeVsLoad.add(response.timings.duration);

    // Add current VU count to response time for correlation
    console.log(
        `Response Time: ${response.timings.duration}ms, Status: ${response.status}`,
    );

    // Minimal sleep to allow for realistic load generation
    sleep(0.1);
}

// Custom summary function to show RPS vs Response Time correlation
export function handleSummary(data) {
    return {
        stdout: textSummary(data, { indent: " ", enableColors: true }),
        "performance_summary.json": JSON.stringify(data, undefined, 2),
    };
}

function textSummary(data, options) {
    let indent = options.indent || "";

    let summary = `
${indent}📊 Performance Summary - RPS vs Response Time Analysis
${indent}═══════════════════════════════════════════════════════
${indent}
${indent}🔥 Key Metrics:
${indent}  Total Requests: ${data.metrics.http_reqs.values.count}
${indent}  Average RPS: ${(data.metrics.http_reqs.values.rate || 0).toFixed(2)}/s
${indent}  Success Rate: ${(100 - (data.metrics.http_req_failed.values.rate || 0) * 100).toFixed(2)}%
${indent}
${indent}⏱️  Response Time Distribution:
${indent}  Average: ${(data.metrics.http_req_duration.values.avg || 0).toFixed(2)}ms
${indent}  Median:  ${(data.metrics.http_req_duration.values.med || 0).toFixed(2)}ms
${indent}  P90:     ${(data.metrics["http_req_duration{expected_response:true}"].values["p(90)"] || 0).toFixed(2)}ms
${indent}  P95:     ${(data.metrics["http_req_duration{expected_response:true}"].values["p(95)"] || 0).toFixed(2)}ms
${indent}  P99:     ${(data.metrics["http_req_duration{expected_response:true}"].values["p(99)"] || 0).toFixed(2)}ms
${indent}
${indent}🚀 Load Test Stages Completed:
${indent}  1 → 5 → 10 → 20 → 30 → 40 → 50 → 25 → 10 → 0 Virtual Users
${indent}
${indent}💡 Analysis Tips:
${indent}  • Check performance_summary.json for detailed data
${indent}  • Look for response time increases as RPS scales up
${indent}  • Monitor when response times start degrading significantly
${indent}
${indent}Next Steps:
${indent}  • Graph the data: cat performance_summary.json | jq '.metrics'
${indent}  • Identify optimal RPS before performance degrades
${indent}  • Use this data to set production capacity limits
    `;

    return summary;
}
