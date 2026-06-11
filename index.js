// Tencent Cloud EdgeOne Serverless VLESS Engine
import { connect } from 'cloudflare:sockets';

const userID = 'f2e17b4d-22fd-44a4-90db-40649717be8e'; // ဆရာကြီးရဲ့ UUID
const proxyIP = '1.1.1.1'; // IP Scanner ဖြင့် ရှာဖွေထားသော Cloudflare Clean IP အသုံးပြုနိုင်သည်

export default {
  async fetch(request, env, ctx) {
    try {
      const upgradeHeader = request.headers.get('Upgrade');
      const url = new URL(request.url);

      // WebSocket စနစ်နှင့် လမ်းကြောင်းအား ကွက်တိ စစ်ဆေးခြင်း
      if (url.pathname === '/www.speedtest.net' && upgradeHeader === 'websocket') {
        return await vlessOverWSHandler(request);
      }

      // ပုံမှန်ဝင်လာပါက Speedtest ဆီ လွှဲ၍ ဟန်ဆောင်ထားခြင်း
      return fetch('https://www.speedtest.net' + url.pathname, {
        headers: request.headers
      });
    } catch (err) {
      return new Response(err.toString(), { status: 500 });
    }
  }
};

async function vlessOverWSHandler(request) {
  const webSocketPair = new WebSocketPair();
  const [client, server] = Object.values(webSocketPair);
  server.accept();

  let remoteSocketWapper = { value: null };

  const readableWebSocketStream = new ReadableStream({
    start(controller) {
      server.addEventListener('message', (event) => controller.enqueue(event.data));
      server.addEventListener('close', () => { try { controller.close(); } catch(e){} });
      server.addEventListener('error', (err) => controller.error(err));
    }
  });

  readableWebSocketStream.pipeTo(new WritableStream({
    async write(chunk, controller) {
      if (remoteSocketWapper.value) {
        const writer = remoteSocketWapper.value.writable.getWriter();
        await writer.write(chunk);
        writer.releaseLock();
        return;
      }

      if (chunk.byteLength < 18) return;
      const version = new Uint8Array(chunk.slice(0, 1));
      let idDiff = chunk.slice(1, 17);
      
      // UUID စစ်ဆေးခြင်း
      if (stringify(new Uint8Array(idDiff)) !== userID) return;

      const optLength = new Uint8Array(chunk.slice(17, 18))[0];
      let addressIndex = 18 + optLength;
      const addressType = new Uint8Array(chunk.slice(addressIndex, addressIndex + 1))[0];

      let address = '';
      if (addressType === 1) {
        address = new Uint8Array(chunk.slice(addressIndex + 1, addressIndex + 5)).join('.');
        addressIndex += 5;
      } else if (addressType === 2) {
        const addressLength = new Uint8Array(chunk.slice(addressIndex + 1, addressIndex + 2))[0];
        address = new TextDecoder().decode(chunk.slice(addressIndex + 2, addressIndex + 2 + addressLength));
        addressIndex += 2 + addressLength;
      } else {
        return;
      }

      const port = new DataView(chunk.slice(addressIndex, addressIndex + 2)).getUint16(0);
      const vlessTailBuffer = chunk.slice(addressIndex + 2);

      // Outbound Target သို့ ဥမင်လှိုဏ်ခေါင်း ဖောက်ခြင်း
      try {
        const tcpSocket = connect({ hostname: address, port: port });
        remoteSocketWapper.value = tcpSocket;
        const writer = tcpSocket.writable.getWriter();
        await writer.write(vlessTailBuffer);
        writer.releaseLock();

        // Handshake Success Response ပြန်ခြင်း
        server.send(new Uint8Array([0, 0]));

        tcpSocket.readable.pipeTo(new WritableStream({
          async write(chunk) { server.send(chunk); },
          close() { server.close(); },
          abort() { server.close(); }
        }));
      } catch (e) {
        server.close();
      }
    }
  })).catch(() => {});

  return new Response(null, { status: 101, webSocket: client });
}

function stringify(arr) {
  const hex = [];
  for (let i = 0; i < arr.length; i++) hex.push((arr[i] < 16 ? '0' : '') + arr[i].toString(16));
  return [hex.slice(0, 4).join(''), hex.slice(4, 6).join(''), hex.slice(6, 8).join(''), hex.slice(8, 10).join(''), hex.slice(10, 16).join('')].join('-');
    }

