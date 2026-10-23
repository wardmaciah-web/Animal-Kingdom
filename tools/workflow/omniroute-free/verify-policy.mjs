// Offline test against the installed OmniRoute rule engine; no provider calls.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {stripTypeScriptTypes} from 'node:module';
import {pathToFileURL} from 'node:url';

const install=process.argv[2] ?? path.join(process.env.APPDATA ?? '', 'npm/node_modules/omniroute');
const source=path.join(install,'open-sse/services');
const scratch=fs.mkdtempSync(path.join(os.tmpdir(),'ak-omniroute-policy-'));
try {
  for(const name of ['wildcardRouter','payloadRules']) {
    const code=stripTypeScriptTypes(fs.readFileSync(path.join(source,name+'.ts'),'utf8'))
      .replace('./wildcardRouter.ts','./wildcardRouter.mjs');
    fs.writeFileSync(path.join(scratch,name+'.mjs'),code);
  }
  const {normalizePayloadRulesConfig,applyPayloadRules}=await import(pathToFileURL(path.join(scratch,'payloadRules.mjs')));
  const rules=normalizePayloadRulesConfig(JSON.parse(fs.readFileSync(new URL('./payload-rules.json',import.meta.url))));
  for(const model of ['cohere/north-mini-code:free','openrouter/cohere/north-mini-code:free']) {
    const {payload}=applyPayloadRules({model,models:['paid/example'],route:'fallback',plugins:[{id:'web'}],preset:'paid',transforms:['x'],service_tier:'priority',web_search_options:{},provider:{allow_fallbacks:true,max_price:{prompt:100},only:['paid']},reasoning:{effort:'high'},max_tokens:999999},model,'openai',rules);
    assert.deepEqual(payload.provider,{only:['cohere'],allow_fallbacks:false,max_price:{prompt:0,completion:0,request:0,image:0}});
    for(const key of ['models','route','plugins','preset','transforms','service_tier','web_search_options']) assert(!(key in payload));
    assert.equal(payload.max_tokens,2048);
    assert.equal(payload.reasoning.effort,'none');
  }
  console.log('PASS: installed native rules pin zero prices, disable fallback, remove paid add-ons and cap output. No network requests.');
} finally {
  // Only the two files this test created are removed; no recursive cleanup.
  for(const name of ['wildcardRouter.mjs','payloadRules.mjs']) {
    const file=path.join(scratch,name);
    if(fs.existsSync(file)) fs.unlinkSync(file);
  }
  fs.rmdirSync(scratch);
}
