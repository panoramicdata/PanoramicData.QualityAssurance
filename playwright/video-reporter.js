/**
 * Custom Playwright Reporter - Video Links Generator
 * 
 * Automatically creates an HTML page with links to all test videos
 * after each test run. Opens automatically in your browser.
 */

const fs = require('fs');
const path = require('path');

class VideoReporter {
  constructor(options) {
    this.videos = [];
    this.startTime = new Date();
  }

  onBegin(config, suite) {
    console.log(`\n📹 Video Reporter: Recording enabled for all tests`);
  }

  onTestEnd(test, result) {
    // Collect video paths from each test
    for (const attachment of result.attachments) {
      if (attachment.name === 'video' && attachment.path) {
        this.videos.push({
          testName: test.title,
          testFile: test.location.file,
          status: result.status,
          duration: result.duration,
          videoPath: attachment.path,
          projectName: test.parent.project()?.name || 'default'
        });
      }
    }
  }

  async onEnd(result) {
    if (this.videos.length === 0) {
      console.log('📹 Video Reporter: No videos recorded');
      return;
    }

    const endTime = new Date();
    const outputDir = path.join(__dirname, 'test-results');
    
    // Create timestamped directory for this test run
    const timestamp = this.startTime.toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const runId = `run-${timestamp}`;
    const runDir = path.join(outputDir, 'video-reports', runId);
    
    const htmlFile = path.join(outputDir, 'test-videos.html'); // Latest report (main)
    const htmlFileArchive = path.join(runDir, 'test-videos.html'); // Archived copy
    const markdownFile = path.join(outputDir, 'test-videos.md');
    const markdownFileArchive = path.join(runDir, 'test-videos.md');

    // Ensure output directories exist
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }
    if (!fs.existsSync(runDir)) {
      fs.mkdirSync(runDir, { recursive: true });
    }

    // Generate HTML report
    const html = this.generateHTML(this.startTime, endTime, result, runId);
    fs.writeFileSync(htmlFile, html);
    fs.writeFileSync(htmlFileArchive, html);

    // Generate Markdown report
    const markdown = this.generateMarkdown(this.startTime, endTime, result);
    fs.writeFileSync(markdownFile, markdown);
    fs.writeFileSync(markdownFileArchive, markdown);
    
    // Update the index of all test runs
    this.updateRunsIndex(outputDir, runId, this.startTime, endTime, this.videos.length);

    // Calculate relative path for display
    const relativeHtmlPath = path.relative(process.cwd(), htmlFile);
    const relativeMarkdownPath = path.relative(process.cwd(), markdownFile);

    console.log('\n═══════════════════════════════════════════════════════');
    console.log('📹 VIDEO REPORT GENERATED');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`   Test Run ID: ${runId}`);
    console.log(`   Videos recorded: ${this.videos.length}`);
    console.log(`   HTML Report: ${relativeHtmlPath}`);
    console.log(`   Markdown:    ${relativeMarkdownPath}`);
    console.log(`   Archived:    test-results/video-reports/${runId}/`);
    console.log('═══════════════════════════════════════════════════════');
    console.log(`\n   Open in browser: file:///${htmlFile.replace(/\\/g, '/')}`);
    console.log('   View all runs: .\\Get-TestVideos.ps1 -Action list-runs');
    console.log('');

    // Try to open in browser automatically (Windows)
    if (process.platform === 'win32') {
      try {
        const { exec } = require('child_process');
        exec(`start "" "${htmlFile}"`);
      } catch (e) {
        // Silent fail if can't open browser
      }
    }
  }

  updateRunsIndex(outputDir, runId, startTime, endTime, videoCount) {
    const indexFile = path.join(outputDir, 'video-reports', 'runs-index.json');
    let runs = [];
    
    // Load existing runs
    if (fs.existsSync(indexFile)) {
      try {
        runs = JSON.parse(fs.readFileSync(indexFile, 'utf8'));
      } catch (e) {
        runs = [];
      }
    }
    
    // Add this run
    runs.unshift({
      runId,
      startTime: startTime.toISOString(),
      endTime: endTime.toISOString(),
      duration: ((endTime - startTime) / 1000).toFixed(2),
      videoCount,
      htmlPath: `video-reports/${runId}/test-videos.html`
    });
    
    // Keep last 50 runs
    runs = runs.slice(0, 50);
    
    fs.writeFileSync(indexFile, JSON.stringify(runs, null, 2));
  }

  generateHTML(startTime, endTime, result, runId) {
    const duration = ((endTime - startTime) / 1000).toFixed(2);
    const passed = this.videos.filter(v => v.status === 'passed').length;
    const failed = this.videos.filter(v => v.status === 'failed').length;
    const flaky = this.videos.filter(v => v.status === 'flaky').length;
    
    // Load previous runs for the history section
    const indexFile = path.join(__dirname, 'test-results', 'video-reports', 'runs-index.json');
    let previousRuns = [];
    if (fs.existsSync(indexFile)) {
      try {
        previousRuns = JSON.parse(fs.readFileSync(indexFile, 'utf8')).slice(0, 10);
      } catch (e) {}
    }
    
    // Group videos by status
    const videosByStatus = {
      failed: this.videos.filter(v => v.status === 'failed'),
      flaky: this.videos.filter(v => v.status === 'flaky'),
      passed: this.videos.filter(v => v.status === 'passed')
    };

    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Videos - ${startTime.toLocaleDateString()} ${startTime.toLocaleTimeString()}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 15px;
        }
        .header p {
            opacity: 0.9;
            font-size: 1.1em;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f8f9fa;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            text-align: center;
        }
        .stat-card .number {
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .stat-card .label {
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .stat-card.passed .number { color: #28a745; }
        .stat-card.failed .number { color: #dc3545; }
        .stat-card.flaky .number { color: #ffc107; }
        .stat-card.total .number { color: #667eea; }
        .content {
            padding: 30px;
        }
        .section {
            margin-bottom: 40px;
        }
        .section h2 {
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .video-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
        }
        .video-card {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            border-left: 4px solid #667eea;
            transition: all 0.3s ease;
            position: relative;
        }
        .video-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 20px rgba(0,0,0,0.15);
        }
        .video-card.failed { border-left-color: #dc3545; }
        .video-card.flaky { border-left-color: #ffc107; }
        .video-card.passed { border-left-color: #28a745; }
        .video-card h3 {
            color: #333;
            font-size: 1.1em;
            margin-bottom: 10px;
            line-height: 1.4;
        }
        .video-card .meta {
            font-size: 0.85em;
            color: #666;
            margin-bottom: 15px;
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 0.75em;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .badge.passed { background: #d4edda; color: #155724; }
        .badge.failed { background: #f8d7da; color: #721c24; }
        .badge.flaky { background: #fff3cd; color: #856404; }
        .video-link {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 10px 20px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: 600;
            transition: all 0.3s ease;
        }
        .video-link:hover {
            background: #5568d3;
            transform: scale(1.05);
        }
        .file-path {
            font-size: 0.75em;
            color: #999;
            margin-top: 10px;
            word-break: break-all;
            font-family: 'Courier New', monospace;
        }
        .empty-state {
            text-align: center;
            padding: 40px;
            color: #999;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 0.9em;
            background: #f8f9fa;
            border-top: 1px solid #dee2e6;
        }
        .quick-actions {
            background: #fff3cd;
            padding: 15px 30px;
            margin: 20px 30px;
            border-radius: 8px;
            border-left: 4px solid #ffc107;
        }
        .quick-actions h3 {
            color: #856404;
            margin-bottom: 10px;
        }
        .quick-actions code {
            background: white;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            color: #e83e8c;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><span>🎬</span> Playwright Test Videos</h1>
            <p>Test run completed on ${startTime.toLocaleDateString()} at ${startTime.toLocaleTimeString()}</p>
            <p>Duration: ${duration}s • Run ID: <code style="background: rgba(255,255,255,0.2); padding: 2px 8px; border-radius: 4px;">${runId}</code></p>
        </div>

        <div class="stats">
            <div class="stat-card total">
                <div class="number">${this.videos.length}</div>
                <div class="label">Total Videos</div>
            </div>
            <div class="stat-card passed">
                <div class="number">${passed}</div>
                <div class="label">Passed</div>
            </div>
            <div class="stat-card failed">
                <div class="number">${failed}</div>
                <div class="label">Failed</div>
            </div>
            <div class="stat-card flaky">
                <div class="number">${flaky}</div>
                <div class="label">Flaky</div>
            </div>
        </div>

        <div class="quick-actions">
            <h3>💡 Quick Access</h3>
            <p>• Open video folder: <code>explorer test-results</code></p>
            <p>• List all test runs: <code>.\\Get-TestVideos.ps1 -Action list-runs</code></p>
            <p>• Open specific run: <code>.\\Get-TestVideos.ps1 -Action open-run -RunId "${runId}"</code></p>
            <p>• Find latest videos: <code>Get-TestVideos</code> (PowerShell function)</p>
        </div>

        ${previousRuns.length > 0 ? `
        <div style="padding: 30px; background: #f8f9fa;">
            <h2 style="margin-bottom: 20px; color: #333;">📚 Previous Test Runs (Last 10)</h2>
            <div style="background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                ${previousRuns.map((run, index) => {
                  const runDate = new Date(run.startTime);
                  const isLatest = index === 0;
                  return `
                    <div style="padding: 15px 20px; border-bottom: 1px solid #dee2e6; display: flex; justify-content: space-between; align-items: center; ${isLatest ? 'background: #e7f3ff; border-left: 4px solid #667eea;' : ''}">
                        <div style="flex: 1;">
                            <div><strong style="color: #333;">${isLatest ? '🔵 ' : ''}${runDate.toLocaleDateString()} ${runDate.toLocaleTimeString()}</strong></div>
                            <div style="color: #666; font-size: 0.85em; margin-top: 4px;">${run.videoCount} videos • ${run.duration}s duration • ${run.runId}</div>
                        </div>
                        <a href="${run.htmlPath}" style="background: #667eea; color: white; padding: 8px 16px; border-radius: 6px; text-decoration: none; font-size: 0.9em; white-space: nowrap; margin-left: 15px;">View Report</a>
                    </div>
                  `;
                }).join('')}
            </div>
        </div>` : ''}

        <div class="content">
            ${failed > 0 ? this.generateSection('Failed Tests', videosByStatus.failed, 'failed') : ''}
            ${flaky > 0 ? this.generateSection('Flaky Tests', videosByStatus.flaky, 'flaky') : ''}
            ${passed > 0 ? this.generateSection('Passed Tests', videosByStatus.passed, 'passed') : ''}
        </div>

        <div class="footer">
            <p>Generated by Playwright Video Reporter • ${new Date().toISOString()}</p>
            <p>Videos are stored in WebM format and can be played in most modern browsers</p>
        </div>
    </div>
</body>
</html>`;
  }

  generateSection(title, videos, status) {
    if (videos.length === 0) return '';

    const icon = status === 'failed' ? '❌' : status === 'flaky' ? '⚠️' : '✅';
    
    const videoCards = videos.map(v => {
      const relPath = path.relative(process.cwd(), v.videoPath).replace(/\\/g, '/');
      const fileUrl = `file:///${v.videoPath.replace(/\\/g, '/')}`;
      const testDuration = (v.duration / 1000).toFixed(2);
      
      return `
        <div class="video-card ${status}">
            <h3>${v.testName}</h3>
            <div class="meta">
                <span class="badge ${status}">${status}</span>
                <span>⏱️ ${testDuration}s</span>
                <span>🎭 ${v.projectName}</span>
            </div>
            <a href="${fileUrl}" class="video-link" target="_blank">▶️ Play Video</a>
            <div class="file-path">${relPath}</div>
        </div>`;
    }).join('');

    return `
      <div class="section">
          <h2>${icon} ${title} (${videos.length})</h2>
          <div class="video-grid">
              ${videoCards}
          </div>
      </div>`;
  }

  generateMarkdown(startTime, endTime, result) {
    const duration = ((endTime - startTime) / 1000).toFixed(2);
    const passed = this.videos.filter(v => v.status === 'passed').length;
    const failed = this.videos.filter(v => v.status === 'failed').length;
    
    let md = `# Test Videos Report\n\n`;
    md += `**Date:** ${startTime.toLocaleDateString()} ${startTime.toLocaleTimeString()}\n`;
    md += `**Duration:** ${duration}s\n\n`;
    md += `## Summary\n\n`;
    md += `- Total Videos: ${this.videos.length}\n`;
    md += `- ✅ Passed: ${passed}\n`;
    md += `- ❌ Failed: ${failed}\n\n`;
    
    md += `## Videos\n\n`;
    
    this.videos.forEach(v => {
      const relPath = path.relative(process.cwd(), v.videoPath);
      const status = v.status === 'passed' ? '✅' : '❌';
      md += `### ${status} ${v.testName}\n\n`;
      md += `- **Status:** ${v.status}\n`;
      md += `- **Duration:** ${(v.duration / 1000).toFixed(2)}s\n`;
      md += `- **Project:** ${v.projectName}\n`;
      md += `- **Video:** [${relPath}](${relPath})\n\n`;
    });
    
    return md;
  }
}

module.exports = VideoReporter;
