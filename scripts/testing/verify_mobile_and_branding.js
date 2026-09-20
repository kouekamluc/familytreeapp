const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

async function run() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const userDataDir = path.join(__dirname, 'chrome-brand-suite');
  try { fs.rmSync(userDataDir, { recursive: true, force: true }); } catch (_) {}

  const artifactsDir = 'C:/Users/kouek/.gemini/antigravity-ide/brain/4c15e57f-dd28-4ac7-8e1d-f40ba864e728';

  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9259',
    '--user-data-dir=' + userDataDir,
    '--window-size=1600,1050',
    '--disable-gpu'
  ]);

  await new Promise(r => setTimeout(r, 2500));

  try {
    const newTabRes = await fetch('http://127.0.0.1:9259/json/new?http://localhost:8080', { method: 'PUT' });
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

    console.log('1. Waiting 7.5s for initial landing portal render...');
    await new Promise(r => setTimeout(r, 7500));

    // 1. Capture Desktop Landing Portal with Kkevo Crest in navbar and Hero section
    console.log('1. Capturing Desktop Landing Hero with Crest...');
    let shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(artifactsDir, 'branding_1_landing_hero.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved branding_1_landing_hero.png');

    // 2. Click "Explore Demo Vault" directly in the top navbar (x: 1180, y: 38)
    console.log('2. Clicking Explore Demo Vault at (1180, 38)...');
    await clickAt(1180, 38, 5000);

    // 3. Capture Authenticated Dashboard Desktop with Kkevo Crest in Sidebar
    console.log('3. Capturing Authenticated Dashboard Sidebar with Crest...');
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(artifactsDir, 'branding_3_authenticated_sidebar.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved branding_3_authenticated_sidebar.png');

    // 4. Emulate Mobile Android Screen (393 x 852, e.g. Pixel 8 / Galaxy S24)
    console.log('4. Emulating Mobile Android screen (393 x 852)...');
    await send('Emulation.setDeviceMetricsOverride', {
      width: 393,
      height: 852,
      deviceScaleFactor: 2.0,
      mobile: true,
      fitWindow: false
    });
    await new Promise(r => setTimeout(r, 3000));

    // 5. Capture Mobile Android Tree View (with Mobile AppBar, Kkevo Crest, and Bottom Nav)
    console.log('5. Capturing Mobile Tree View...');
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(artifactsDir, 'mobile_1_tree_view.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved mobile_1_tree_view.png');

    // 6. Tap Registry in Mobile Bottom Nav (Item 1: x: 147, y: 825)
    console.log('6. Tapping Registry in Mobile Bottom Nav...');
    await clickAt(147, 825, 2500);
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(artifactsDir, 'mobile_2_registry.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved mobile_2_registry.png');

    // 7. Tap Kinship in Mobile Bottom Nav (Item 2: x: 245, y: 825)
    console.log('7. Tapping Kinship in Mobile Bottom Nav...');
    await clickAt(245, 825, 2500);
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(artifactsDir, 'mobile_3_kinship.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved mobile_3_kinship.png');

    // 8. Tap Alliances in Mobile Bottom Nav (Item 3: x: 344, y: 825)
    console.log('8. Tapping Alliances in Mobile Bottom Nav...');
    await clickAt(344, 825, 2500);
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(artifactsDir, 'mobile_4_alliances.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved mobile_4_alliances.png');

    // 9. Reset to Desktop and Logout to capture Login Modal
    console.log('9. Resetting to Desktop metrics...');
    await send('Emulation.clearDeviceMetricsOverride');
    await new Promise(r => setTimeout(r, 2000));

    // Sign out button in sidebar (bottom right of curator card: x: 245, y: 955)
    console.log('Signing out to return to landing...');
    await clickAt(245, 955, 3000);

    // Click "Sign In" at (1330, 38)
    console.log('Clicking Sign In to capture Login Modal...');
    await clickAt(1330, 38, 2000);
    shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(artifactsDir, 'branding_2_login_modal.png'), Buffer.from(shot.result.data, 'base64'));
    console.log('Saved branding_2_login_modal.png');

    console.log('--- ALL MOBILE & BRANDING VERIFICATIONS COMPLETE ---');
    ws.close();
  } catch (err) {
    console.error('Error during test execution:', err);
  } finally {
    chrome.kill();
    try { fs.rmSync(userDataDir, { recursive: true, force: true }); } catch (_) {}
  }
}

run();
