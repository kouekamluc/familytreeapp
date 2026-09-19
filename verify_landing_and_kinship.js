const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

async function run() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const userDataDir = path.join(__dirname, 'chrome-temp-profile');
  
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    `--user-data-dir=${userDataDir}`,
    '--window-size=1600,1050',
    '--disable-gpu'
  ]);

  await new Promise(r => setTimeout(r, 2000));

  try {
    const newTabRes = await fetch('http://127.0.0.1:9222/json/new?http://localhost:5173/', { method: 'PUT' });
    const tabData = await newTabRes.json();
    const wsUrl = tabData.webSocketDebuggerUrl;

    const ws = new WebSocket(wsUrl);

    let id = 1;
    const callbacks = new Map();
    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && callbacks.has(msg.id)) {
        callbacks.get(msg.id)(msg);
      }
    };

    const send = (method, params = {}) => {
      return new Promise((resolve) => {
        const msgId = id++;
        callbacks.set(msgId, (res) => resolve(res));
        ws.send(JSON.stringify({ id: msgId, method, params }));
      });
    };

    await new Promise(r => ws.onopen = r);

    await send('Page.enable');
    await send('Runtime.enable');

    // 1. Capture Landing Page
    await new Promise(r => setTimeout(r, 2000));
    let shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'landing_page_redesign.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved landing_page_redesign.png');

    // 2. Login to test authenticated views
    await send('Page.navigate', { url: 'http://localhost:5173/login' });
    await new Promise(r => setTimeout(r, 2000));

    await send('Runtime.evaluate', {
      expression: `
        (() => {
          const buttons = document.querySelectorAll('button');
          for (let b of buttons) {
            if (b.innerText.toLowerCase().includes('quick demo login')) {
              b.click();
              return 'clicked quick demo';
            }
          }
          return 'none';
        })()
      `
    });

    await new Promise(r => setTimeout(r, 2000));

    // 3. Test Kinship Calculator on /relationships
    await send('Page.navigate', { url: 'http://localhost:5173/relationships' });
    await new Promise(r => setTimeout(r, 2500));
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'kinship_calculator_interactive.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved kinship_calculator_interactive.png');

    // 4. Test Ancestor Mode in /tree
    await send('Page.navigate', { url: 'http://localhost:5173/tree' });
    await new Promise(r => setTimeout(r, 2500));

    // Click on "📜 Ancestors" button
    await send('Runtime.evaluate', {
      expression: `
        (() => {
          const buttons = document.querySelectorAll('button');
          for (let b of buttons) {
            if (b.innerText.toLowerCase().includes('ancestors')) {
              b.click();
              return 'clicked ancestors mode';
            }
          }
          return 'not found';
        })()
      `
    });

    await new Promise(r => setTimeout(r, 2000));
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'ancestor_feature_fixed.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved ancestor_feature_fixed.png');

    ws.close();
  } catch (err) {
    console.error('Error:', err);
  } finally {
    chrome.kill();
  }
}

run();
