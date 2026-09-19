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
    const newTabRes = await fetch('http://127.0.0.1:9222/json/new?http://localhost:5173/login', { method: 'PUT' });
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

    await new Promise(r => setTimeout(r, 1500));

    // Login via demo
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
          for (let b of buttons) {
            if (b.innerText.toLowerCase().includes('sign in') || b.type === 'submit') {
              b.click();
              return 'clicked sign in';
            }
          }
          return 'none';
        })()
      `
    });

    await new Promise(r => setTimeout(r, 2500));

    // 1. Capture Tree View
    await send('Page.navigate', { url: 'http://localhost:5173/tree' });
    await new Promise(r => setTimeout(r, 3000));
    let shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'current_tree_render.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved current_tree_render.png');

    // 2. Capture Person Detail Page (Tadji Jean - ID 2)
    await send('Page.navigate', { url: 'http://localhost:5173/people/2' });
    await new Promise(r => setTimeout(r, 2500));
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'person_detail_breadcrumbs.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved person_detail_breadcrumbs.png');

    // 3. Capture People Directory
    await send('Page.navigate', { url: 'http://localhost:5173/people' });
    await new Promise(r => setTimeout(r, 2500));
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'people_directory_ux.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved people_directory_ux.png');

    // 4. Capture Relationships Page
    await send('Page.navigate', { url: 'http://localhost:5173/relationships' });
    await new Promise(r => setTimeout(r, 2500));
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'relationships_lineage.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved relationships_lineage.png');

    ws.close();
  } catch (err) {
    console.error('Error:', err);
  } finally {
    chrome.kill();
  }
}

run();
