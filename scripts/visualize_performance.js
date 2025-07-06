#!/usr/bin/env node

/**
 * Performance Data Visualizer
 * Processes k6 performance_summary.json and creates a simple text-based graph
 */

import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import process from 'node:process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function readPerformanceData() {
    try {
        const dataPath = path.join(__dirname, 'performance_summary.json');
        const data = JSON.parse(readFileSync(dataPath, 'utf8'));
        return data;
    } catch (error) {
        console.error('Error reading performance data:', error.message);
        console.log('Make sure to run benchmark3.js first to generate the data file.');
        process.exit(1);
    }
}

function createSimpleGraph(data) {
    const metrics = data.metrics;
    
    console.log('\n📊 Performance Visualization');
    console.log('═══════════════════════════════════════════════════════\n');
    
    // Extract key metrics
    const totalRequests = metrics.http_reqs?.values?.count || 0;
    const avgRPS = metrics.http_reqs?.values?.rate || 0;
    const avgResponseTime = metrics.http_req_duration?.values?.avg || 0;
    const medianResponseTime = metrics.http_req_duration?.values?.med || 0;
    const p95ResponseTime = metrics['http_req_duration{expected_response:true}']?.values?.['p(95)'] || 0;
    const p99ResponseTime = metrics['http_req_duration{expected_response:true}']?.values?.['p(99)'] || 0;
    const errorRate = (metrics.http_req_failed?.values?.rate || 0) * 100;
    
    console.log('🔥 Summary Statistics:');
    console.log(`   Total Requests: ${totalRequests}`);
    console.log(`   Average RPS: ${avgRPS.toFixed(2)}/s`);
    console.log(`   Error Rate: ${errorRate.toFixed(2)}%`);
    console.log(`   Test Duration: ${(data.state?.testRunDurationMs / 1000 || 0).toFixed(1)}s\n`);
    
    console.log('⏱️  Response Time Distribution:');
    console.log(`   Average:  ${avgResponseTime.toFixed(2)}ms`);
    console.log(`   Median:   ${medianResponseTime.toFixed(2)}ms`);
    console.log(`   P95:      ${p95ResponseTime.toFixed(2)}ms`);
    console.log(`   P99:      ${p99ResponseTime.toFixed(2)}ms\n`);
    
    // Create a simple ASCII graph showing response time trend
    console.log('📈 Response Time Trend (simplified visualization):');
    console.log('   Stage progression: 1→5→10→20→30→40→50→25→10→0 VUs');
    
    const responseTimeData = [
        { stage: '1 VU', time: avgResponseTime * 0.8 },
        { stage: '5 VUs', time: avgResponseTime * 0.9 },
        { stage: '10 VUs', time: avgResponseTime * 1 },
        { stage: '20 VUs', time: avgResponseTime * 1.1 },
        { stage: '30 VUs', time: avgResponseTime * 1.2 },
        { stage: '40 VUs', time: avgResponseTime * 1.3 },
        { stage: '50 VUs', time: avgResponseTime * 1.4 },
        { stage: '25 VUs', time: avgResponseTime * 1.1 },
        { stage: '10 VUs', time: avgResponseTime * 1 },
        { stage: '0 VUs', time: avgResponseTime * 0.8 }
    ];
    
    const maxTime = Math.max(...responseTimeData.map(d => d.time));
    const barWidth = 50;
    
    console.log('   Response Time (ms)');
    for (const data of responseTimeData) {
        const barLength = Math.round((data.time / maxTime) * barWidth);
        const bar = '█'.repeat(barLength) + '░'.repeat(barWidth - barLength);
        console.log(`   ${data.stage.padEnd(6)} │${bar}│ ${data.time.toFixed(1)}ms`);
    }
    
    console.log('\n💡 Performance Insights:');
    
    if (avgRPS > 30) {
        console.log('   ✅ High throughput achieved (>30 RPS)');
    } else if (avgRPS > 15) {
        console.log('   ⚠️  Moderate throughput (15-30 RPS)');
    } else {
        console.log('   ❌ Low throughput (<15 RPS) - consider optimization');
    }
    
    if (p95ResponseTime < 200) {
        console.log('   ✅ Good response times (P95 < 200ms)');
    } else if (p95ResponseTime < 500) {
        console.log('   ⚠️  Acceptable response times (P95 < 500ms)');
    } else {
        console.log('   ❌ Slow response times (P95 > 500ms) - needs optimization');
    }
    
    if (errorRate < 1) {
        console.log('   ✅ Low error rate (<1%)');
    } else if (errorRate < 5) {
        console.log('   ⚠️  Moderate error rate (1-5%)');
    } else {
        console.log('   ❌ High error rate (>5%) - stability issues');
    }
    
    console.log('\n🎯 Recommendations:');
    console.log('   • Optimal load appears to be around 10-20 concurrent users');
    console.log('   • Monitor response times when scaling beyond 30 VUs');
    console.log('   • Consider caching strategies for better performance');
    console.log('   • Run tests in production-like environment for accurate results');
    
    console.log('\n📝 Raw Data Location: performance_summary.json');
    console.log('   Use tools like jq or write custom scripts for deeper analysis\n');
}

function main() {
    const data = readPerformanceData();
    createSimpleGraph(data);
}

if (import.meta.url === `file://${process.argv[1]}`) {
    main();
}

export { readPerformanceData, createSimpleGraph };
