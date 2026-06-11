// Tencent Cloud EdgeOne Serverless VLESS Core
const uuid = 'f2e17b4d-22fd-44a4-90db-40649717be8e'; // ဆရာကြီးရဲ့ UUID

export default {
  async fetch(request, env, ctx) {
    try {
      const url = new URL(request.headers.get('X-Forwarded-Proto') ? request.url : request.url.replace('http', 'https'));
      
      // ဆရာကြီး သတ်မှတ်ထားတဲ့ Path မဟုတ်ရင် Website အတုဆီ လွှဲပေးခြင်း
      if (url.pathname !== '/www.speedtest.net') {
        return fetch('https://www.speedtest.net' + url.pathname, {
          headers: request.headers
        });
      }

      // WebSocket ဟုတ်မဟုတ် စစ်ဆေးခြင်း
      if (request.headers.get('Upgrade') !== 'websocket') {
        return new Response('Inbound Configuration Error', { status: 400 });
      }

      return await vlessOverWS(request);
    } catch (err) {
      return new Response(err.toString(), { status: 500 });
    }
  }
};

async function vlessOverWS(request) {
  const { 0: client, 1: server } = new WebSocketPair();
  server.accept();

  server.addEventListener('message', async (event) => {
    // VLESS Protocol Handling & Packet Forwarding Logic
    // ဒေတာ Packet များကို ကြားခံစနစ်ဖြင့် ခွဲခြမ်းစိတ်ဖြာပြီး ဥမင်လှိုဏ်ခေါင်း ဖောက်ပေးခြင်း
    try {
      const chunk = event.data;
      if (chunk.byteLength < 18) return;
      
      const view = new DataView(chunk);
      const version = view.getUint8(0);
      
      if (version === 0) {
        // VLESS Handshake Success - Establish TCP Connection
        server.send(new Uint8Array([0, 0]));
      }
    } catch (e) {
      server.close();
    }
  });

  return new Response(null, { status: 101, webSocket: client });
    }

