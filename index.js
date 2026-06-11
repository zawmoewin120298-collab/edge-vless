// Tencent Cloud EdgeOne / Cloudflare Workers VLESS Serverless Core
import { connect } from 'cloudflare:sockets';

const userID = 'f2e17b4d-22fd-44a4-90db-40649717be8e'; // ဆရာကြီးရဲ့ UUID
const proxyIP = 'cdn.anycast.eu.org'; // ကြားခံ Anycast IP (လိုအပ်ပါက ပြောင်းလဲနိုင်သည်)

export default {
  async fetch(request, env, ctx) {
    try {
      const upgradeHeader = request.headers.get('Upgrade');
      const url = new URL(request.url);

      // Path စစ်ဆေးခြင်း
      if (url.pathname === '/www.speedtest.net' && upgradeHeader === 'websocket') {
        return await vlessOverWSHandler(request);
      }

      // သတ်မှတ် Path မဟုတ်ပါက ပုံမှန် Website အဖြစ် ဟန်ဆောင်ခြင်း
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

  let address = '';
  let portWithRandomLog = '';
  const log = (info, sep) => {
    console.log(`[${address}:${portWithRandomLog}] ${info}`, sep || '');
  };

  let remoteSocketWapper = {
    value: null,
  };

  // UDP session handle ရန်
  let isDNS = false;

  // WebSocket အဝင်ဒေတာအား ပတ်လမ်းဖောက်ခြင်း
  const readableWebSocketStream = makeReadableWebSocketStream(server, log);

  readableWebSocketStream.pipeTo(new WritableStream({
    async write(chunk, controller) {
      if (remoteSocketWapper.value) {
        const writer = remoteSocketWapper.value.writable.getWriter();
        await writer.write(chunk);
        writer.releaseLock();
        return;
      }

      // VLESS Protocol Handshake အပိုင်းအား စစ်ဆေးခွဲခြမ်းခြင်း
      if (chunk.byteLength < 18) {
        log('Readable protocol version error (too short)');
        return;
      }

      const version = new Uint8Array(chunk.slice(0, 1));
      let idDiff = chunk.slice(1, 17);
      
      // UUID စစ်ဆေးခြင်း
      if (stringify(new Uint8Array(idDiff)) !== userID) {
        log('Authentication Failed (UUID mismatch)');
        return;
      }

      const optLength = new Uint8Array(chunk.slice(17, 18))[0];
      let addressIndex = 18 + optLength;
      const addressType = new Uint8Array(chunk.slice(addressIndex, addressIndex + 1))[0];

      // Address Type ခွဲခြားခြင်း (IPv4, Domain, IPv6)
      if (addressType === 1) {
        address = new Uint8Array(chunk.slice(addressIndex + 1, addressIndex + 5)).join('.');
        addressIndex += 5;
      } else if (addressType === 2) {
        const addressLength = new Uint8Array(chunk.slice(addressIndex + 1, addressIndex + 2))[0];
        address = new TextDecoder().decode(chunk.slice(addressIndex + 2, addressIndex + 2 + addressLength));
        addressIndex += 2 + addressLength;
      } else if (addressType === 3) {
        address = ''; // IPv6 မသုံးသေးပါ
        addressIndex += 17;
      } else {
        log(`Unknown address type: ${addressType}`);
        return;
      }

      const portBuffer = chunk.slice(addressIndex, addressIndex + 2);
      const port = new DataView(portBuffer).getUint16(0);
      portWithRandomLog = port;

      const vlessTailStart = addressIndex + 2;
      const vlessTailBuffer = chunk.slice(vlessTailStart);

      // Target Server ဆီ TCP Outbound Socket ချိတ်ဆက်ခြင်း
      log(`Connecting to outbound target: ${address}:${port}`);
      handleTCPOutbound(remoteSocketWapper, address, port, vlessTailBuffer, server, log);
    },
    close() {
      log('ReadableWebSocketStream closed');
    },
    abort(reason) {
      log('ReadableWebSocketStream aborted', reason);
    },
  })).catch((err) => {
    log('Pipeline processing error', err);
  });

  return new Response(null, { status: 101, webSocket: client });
}

async function handleTCPOutbound(remoteSocketWapper, address, port, initialData, webSocket, log) {
  try {
    const tcpSocket = connect({ hostname: address, port: port });
    remoteSocketWapper.value = tcpSocket;

    const writer = tcpSocket.writable.getWriter();
    await writer.write(initialData); // Handshake response နှင့် ဒေတာဦးစွာပို့ခြင်း
    writer.releaseLock();

    // VLESS Handshake Success Response အား ဖုန်းဘက်ပြန်ပို့ခြင်း
    webSocket.send(new Uint8Array([0, 0]));

    // Remote TCP socket မှ ဒေတာများကို WebSocket ဆီ ပြန်စုပ်တင်ခြင်း
    tcpSocket.readable.pipeTo(new WritableStream({
      async write(chunk, controller) {
        webSocket.send(chunk);
      },
      close() {
        webSocket.close();
      },
      abort(reason) {
        webSocket.close();
      }
    }));
  } catch (error) {
    log(`Outbound Connection Failed: ${error.toString()}`);
    webSocket.close();
  }
}

function makeReadableWebSocketStream(webSocket, log) {
  let eventListenerAdded = false;
  return new ReadableStream({
    start(controller) {
      webSocket.addEventListener('message', (event) => {
        controller.enqueue(event.data);
      });
      webSocket.addEventListener('close', () => {
        safeClose(controller);
      });
      webSocket.addEventListener('error', (err) => {
        controller.error(err);
      });
    },
    cancel(reason) {
      webSocket.close();
    }
  });
}

function safeClose(controller) {
  try { controller.close(); } catch (e) {}
}

function stringify(arr) {
  const hex = [];
  for (let i = 0; i < arr.length; i++) {
    hex.push((arr[i] < 16 ? '0' : '') + arr[i].toString(16));
  }
  return [
    hex.slice(0, 4).join(''),
    hex.slice(4, 6).join(''),
    hex.slice(6, 8).join(''),
    hex.slice(8, 10).join(''),
    hex.slice(10, 16).join('')
  ].join('-');
    }

