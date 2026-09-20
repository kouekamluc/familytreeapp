const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

async function run() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const userDataDir = path.join(__dirname, 'chrome-test-suite');
  try { fs.rmSync(userDataDir, { recursive: true, force: true }); } catch (_) {}

  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9247',
    '--user-data-dir=' + userDataDir,
    '--window-size=1600,1050',
    '--disable-gpu'
  ]);

  await new Promise(r => setTimeout(r, 2500));

  try {
    const newTabRes = await fetch('http://127.0.0.1:9247/json/new?http://localhost:8080', { method: 'PUT' });
    const tabData = await newTabRes.json();
    const ws = new WebSocket(tabData.webSocketDebuggerUrl);

    let id = 1;
    const callbacks = new Map();
    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && callbacks.has(msg.id)) callbacks.get(msg.id)(msg);
    };

    const send = (method, params = {}) => new Promise((resolve) => {
      const msgId = id++;
      callbacks.set(msgId, resolve);
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });

    await new Promise(r => ws.onopen = r);
    await send('Page.enable');
    await send('Runtime.enable');

    const clickAt = async (x, y, waitMs = 2500) => {
      console.log(`Clicking at (${x}, ${y})...`);
      await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
      await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
      await new Promise(r => setTimeout(r, waitMs));
    };

    console.log('1. Waiting 7s for Public Landing Portal initialization...');
    await new Promise(r => setTimeout(r, 7000));

    // 1. Capture Public Landing
    let shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'suite_1_landing_portal.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved suite_1_landing_portal.png');

    // 2. Click "Explore Demo Vault" button in the top navbar (x: 1180, y: 38)
    console.log('2. Clicking Explore Demo Vault at 1180, 38...');
    await clickAt(1180, 38, 5000);

    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'suite_2_tree_canvas.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved suite_2_tree_canvas.png');

    // 3. Navigate to Family Registry (Sidebar Item 1: x: 120, y: 255)
    console.log('3. Navigating to Family Registry at 120, 255...');
    await clickAt(120, 255, 3000);

    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'suite_3_family_registry.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved suite_3_family_registry.png');

    // 4. Navigate to Kinship Solver (Sidebar Item 2: x: 120, y: 325)
    console.log('4. Navigating to Kinship Solver at 120, 325...');
    await clickAt(120, 325, 3000);

    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'suite_4_kinship_solver.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved suite_4_kinship_solver.png');

    // 5. Navigate to Royal Alliances (Sidebar Item 3: x: 120, y: 395)
    console.log('5. Navigating to Royal Alliances at 120, 395...');
    await clickAt(120, 395, 3000);

    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'suite_5_royal_alliances.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved suite_5_royal_alliances.png');

    // 6. Return to Family Tree (x: 120, y: 185) and toggle Senior / Large Text Mode (x: 230, y: 838)
    console.log('6. Returning to Family Tree at 120, 185...');
    await clickAt(120, 185, 2500);

    console.log('7. Toggling Senior / Large Text Mode switch at 230, 838...');
    await clickAt(230, 838, 3000);

    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'suite_6_senior_large_text.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved suite_6_senior_large_text.png');

    ws.close();
    console.log('Suite testing finished successfully!');
  } catch (err) {
    console.error('Error during suite verification:', err);
  } finally {
    chrome.kill();
    try { fs.rmSync(userDataDir, { recursive: true, force: true }); } catch (_) {}
  }
}

run();
