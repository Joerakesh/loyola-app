const adminConsoleHtml = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Loyola Admin</title>
<style>
:root{color-scheme:dark;--bg:#090d12;--panel:#111923;--line:#263342;--muted:#91a0b2;--accent:#c7f36b}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:#f4f7fb;font:15px Inter,system-ui,sans-serif}
main{max-width:1080px;margin:auto;padding:36px 22px}.top{display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap}
h1{font-size:28px;margin:0}p{color:var(--muted)}.pill{color:var(--accent);border:1px solid #52672d;border-radius:30px;padding:7px 12px;font-size:12px}
.panel,.tile{background:var(--panel);border:1px solid var(--line);border-radius:18px;padding:20px}
.auth{display:flex;gap:10px;margin:28px 0}.auth input{flex:1;min-width:0;background:#0b1118;border:1px solid var(--line);border-radius:10px;padding:13px;color:white}
button{background:var(--accent);color:#111;padding:12px 18px;border:0;border-radius:10px;font-weight:700;cursor:pointer}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px;margin-top:18px}.tile small{color:var(--muted)}.tile strong{display:block;font-size:18px;margin-top:10px}
#status{color:var(--muted);margin-top:12px}.hidden{display:none}
</style></head><body><main><div class="top"><div><h1>Loyola Admin Console</h1><p>Administrative workspace · restricted access</p></div><span class="pill">ADMIN ACCESS</span></div>
<section class="panel"><h2>Sign in to administration</h2><p>Paste a valid Loyola app session token. It is kept in memory only and is not stored in your browser.</p>
<div class="auth"><input id="token" type="password" autocomplete="off" placeholder="Bearer session token"><button id="connect">Connect</button></div><div id="status" role="status">Admin access is verified by the backend allowlist.</div></section>
<section id="content" class="hidden"><div class="top" style="margin-top:28px"><h2>System overview</h2><button id="disconnect">Sign out</button></div>
<div class="grid"><article class="tile"><small>Signed in as</small><strong id="adminEmail">—</strong></article><article class="tile"><small>API service</small><strong id="serviceStatus">—</strong></article><article class="tile"><small>Admin authorization</small><strong id="adminStatus">—</strong></article><article class="tile"><small>Last checked</small><strong id="checkedAt">—</strong></article></div>
<h2 style="margin-top:30px">Management areas</h2><div class="grid">
<article class="tile"><small>Campus communication</small><strong>Announcements & events</strong><p>Admin publishing workflow is not enabled yet.</p></article>
<article class="tile"><small>Student support</small><strong>Helpdesk requests</strong><p>Staff assignment and request tracking are planned for the next release.</p></article>
<article class="tile"><small>Platform operations</small><strong>Sync & service health</strong><p>Operational monitoring endpoints will be connected in a later batch.</p></article>
</div></section></main>
<script>
let sessionToken='';
const statusEl=document.getElementById('status');
document.getElementById('connect').addEventListener('click',async()=>{
 const token=document.getElementById('token').value.trim();if(!token){statusEl.textContent='Enter your session token.';return}
 statusEl.textContent='Verifying administrator access…';
 try{const response=await fetch('/api/v1/admin/overview',{headers:{Authorization:'Bearer '+token}});
 const data=await response.json();if(!response.ok)throw new Error(data.message||'Access denied');
 sessionToken=token;document.getElementById('adminEmail').textContent=data.admin.email;
 document.getElementById('serviceStatus').textContent=data.service.status;
 document.getElementById('adminStatus').textContent='Verified';
 document.getElementById('checkedAt').textContent=new Date(data.generatedAt).toLocaleString();
 document.getElementById('content').classList.remove('hidden');document.getElementById('token').value='';
 statusEl.textContent='Administrator verified.';
 }catch(error){sessionToken='';document.getElementById('content').classList.add('hidden');statusEl.textContent=error.message}
});
document.getElementById('disconnect').addEventListener('click',()=>{sessionToken='';document.getElementById('content').classList.add('hidden');statusEl.textContent='Signed out.'});
</script></body></html>`;
export default adminConsoleHtml;
